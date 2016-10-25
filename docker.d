#!/usr/bin/env rdmd --compiler=ldc2

import std.stdio, std.getopt, std.string, std.typecons, std.process, std.algorithm;

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

// cmd1 -o1 -o2 cmd2 -o3 --o4 val1 cmd3 cmd4 --x val2

string[][] cmdopts(string args[]) {
    string[] groupedArgs = [];
    string[][] commandGroups = [][];
    for (int i = 0; i < args.length; ++i) {
        bool isCommand = args[i].indexOf("-") != 0;
        if (isCommand) {
            bool prevArgExpectsValue = i > 0 && args[i - 1].indexOf("--") == 0;
            if (prevArgExpectsValue) {
                isCommand = false;
            }
        }
        if (isCommand) {
            if (groupedArgs.length) {
                commandGroups ~= groupedArgs;
            }
            groupedArgs = [args[i]];
            continue;
        }
        groupedArgs ~= args[i];
    }
    if (groupedArgs.length) {
        commandGroups ~= groupedArgs;
    }
    return commandGroups;
}

int main(string[] args) {
    auto commandGroups = cmdopts(args);
    if (commandGroups.length > 2) {
        writeln("Too many commands found");
        return 1;
    }
    if (commandGroups.length < 2) {
        writeln("Expected command");
        return 1;
    }

    auto command = commandGroups[1][0];
    auto commandArgs = commandGroups[1];
    switch (command) {
        case "delete-containers":
            deleteContainers(commandArgs);
            break;
        case "delete-dangling":
            deleteDanglingImages(commandArgs);
        default:
            writeln("Invalid command");
            return 1;
    }

    return 0;
}
