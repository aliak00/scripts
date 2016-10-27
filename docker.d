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
        return;
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

struct CommandGroup {
    string[] args;
    string command;

    this(string command) {
        this.command = command;
        this.args = [command];
    }
}

CommandGroup[] parseCommandGroups(string args[]) {
    if (args.length == 0) {
        return [];
    }

    if (args[0].length == 0 || args[0][0] == '-') {
        return [];
    }

    CommandGroup[] commandGroups = [CommandGroup(args[0])];
    for (int argIndex = 1, commandIndex = 0; argIndex < args.length; ++argIndex) {
        auto arg = args[argIndex];
        bool isCommand = arg.indexOf("-") != 0;
        if (isCommand) {
            bool prevArgExpectsValue = argIndex > 0 && args[argIndex - 1].indexOf("--") == 0;
            if (prevArgExpectsValue) {
                isCommand = false;
            } else {
                commandGroups ~= CommandGroup(arg);
                commandIndex++;
                continue;
            }
        }
        commandGroups[commandIndex].args ~= arg;
    }
    return commandGroups;
}

unittest {
    auto args = ["cmd1", "-o1", "-o2", "cmd2", "-o3", "--o4", "val1", "cmd3", "cmd4", "--x", "val2"];
    auto groups = parseCommandGroups(args);
    assert(groups.length == 4);
    assert(groups[0].command == "cmd1");
    assert(groups[1].command == "cmd2");
    assert(groups[2].command == "cmd3");
    assert(groups[3].command == "cmd4");
    assert(groups[0].args.length == 3);
    assert(groups[1].args.length == 4);
    assert(groups[2].args.length == 1);
    assert(groups[3].args.length == 3);
}

int main(string[] args) {
    version (unittest) {
        writeln("tests passed");
        return 1;
    }

    auto commandGroups = parseCommandGroups(args);
    if (commandGroups.length > 2) {
        writeln("Too many commands found");
        return 1;
    }
    if (commandGroups.length < 2) {
        writeln("Expected command");
        return 1;
    }

    auto cg = commandGroups[1];
    switch (cg.command) {
        case "delete-containers":
            deleteContainers(cg.args);
            break;
        case "delete-dangling":
            deleteDanglingImages(cg.args);
        default:
            writeln("Invalid command");
            return 1;
    }

    return 0;
}
