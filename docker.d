#!/usr/bin/env rdmd --compiler=ldc2

import std.stdio, std.getopt, std.string, std.typecons, std.process, std.algorithm;

bool looksLikeCommand(string arg) {
    return arg.indexOf("--") != 0
        && arg.indexOf("-") != 0;
}

Tuple!(string[], string[]) parseCommandLine(string[] args) {
    string[] empty = [];
    if (args.length == 0) {
        return tuple(empty, empty);
    }
    for (int i = 1; i < args.length; ++i) {
        string arg = args[i];
        if (arg.looksLikeCommand) {
            bool hasNext = i + 1 < args.length;
            if (hasNext && args[i + 1].looksLikeCommand) {
                continue;
            }
            return tuple(args[1..i], args[i..args.length]);
        }
    }
    return tuple(empty, empty);
}

void execute(string command) {
    writeln("Executing command: ", command);
    auto result = executeShell(command);
    writeln(result.output);
}

void deleteContainers(string[] args) {
    bool force = false;
    auto getoptResult = getopt(
        args,
        "force|f", "Delete running contianers as well", &force
    );

    if (getoptResult.helpWanted) {
        defaultGetoptPrinter("delete-containers expects:", getoptResult.options);
    }

    auto findContainers = "docker ps -q -a";
    auto forceOption = "";
    if (!force) {
        findContainers ~= " -f status=exited";
    } else {
        forceOption = "-f";
    }

    auto command = "docker rm %s $(%s)".format(forceOption, findContainers);
    execute(command);
}

void deleteDanglingImages(string[] args) {
    auto command = "docker rmi $(docker images -q -f dangling=true)";
    execute(command);
}

int main(string[] args) {
    auto data = parseCommandLine(args);
    if (data[1].length == 0) {
        writeln("Expected a command");
        return 1;
    }

    switch (data[1][0]) {
        case "delete-containers":
            deleteContainers(data[1]);
            break;
        case "delete-dangling":
            deleteDanglingImages(data[1]);
        default:
            writeln("Invalid command");
            return 1;
    }

    return 0;
}