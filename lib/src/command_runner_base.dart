import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'arguments.dart';
import 'exceptions.dart';

class CommandRunner {
  FutureOr<void> Function(Object)? onError;

  CommandRunner({this.onError});

  final Map<String, Command> _commands = {};

  UnmodifiableSetView<Command> get commands =>
      UnmodifiableSetView({..._commands.values});

  Future<void> run(List<String> args) async {
    try {
      final ArgResults results = parse(args);
      if (results.command != null) {
        Object? output = await results.command!.run(results);
        print(output.toString());
      }
    } on Exception catch (exception) {
      if (onError != null) {
        onError!(exception);
      } else {
        rethrow;
      }
    }
  }

  ArgResults parse(List<String> args) {
    var results = ArgResults();
    if (args.isEmpty) return results;

    // Throw an exception if the command is not recognized
    if (_commands.containsKey(args.first)) {
      results.command = _commands[args.first];
      args = args.sublist(1);
    } else {
      throw ArgumentException(
        'The first word of input must be a command',
        null,
        args.first,
      );
    }

    // Throw an exception if multiple commands are provided.
    if (results.command != null &&
        args.isNotEmpty &&
        _commands.containsKey(args.first)) {
      throw ArgumentException(
        'Input can only contain one command. Got ${args.first} and ${results.command!.name}',
        null,
        args.first,
      );
    }

    // Setion: Handle options, including flags.
    Map<Option, Object?> argsOptionMap = {};
    int i = 0;
    while (i < args.length) {
      final arg = args[i];
      if (arg.startsWith("-")) {
        final baseArg = _removeDashes(arg);
        // Throw an exception if the option is not recognized
        var option = results.command!.options.firstWhere(
          (opt) => opt.name == baseArg || opt.abbr == baseArg,
          orElse: () => throw ArgumentException(
            "The option $arg is not recognized",
            null,
            arg,
          ),
        );

        if (option.type == OptionType.flag) {
          argsOptionMap[option] = true;
          i++;
          continue;
        }

        if (option.type == OptionType.option) {
          // Throw an exception if the option is not followed by a value
          if (i + 1 >= args.length) {
            throw ArgumentException(
              "The option ${option.name} must be followed by a value",
              results.command!.name,
              option.name,
            );
          }

          if (args[i + 1].startsWith("-")) {
            throw ArgumentException(
              "The option ${option.name} must be followed by a value. Got another option instead '${args[i + 1]}'.",
              results.command!.name,
              option.name,
            );
          }

          var arg = args[i + 1];
          // set the value
          argsOptionMap[option] = arg;
          i++;
        }
      } else {
        // Throw an exception if more than one positional argument is provided
        if (results.commandArg != null && results.commandArg!.isNotEmpty) {
          throw ArgumentException(
            'Commands can only have up to one argument.',
            results.command!.name,
            arg,
          );
        }
        results.commandArg = arg;
      }
      i++;
    }
    results.options = argsOptionMap;

    return results;
  }

  void addCommand(Command command) {
    _commands[command.name] = command;
    command.runner = this;
  }

  // Returns usage for the executable only.
  // Should be overridden if you aren't using [HelpCommand]
  // or another means of printing usage.
  String get usage {
    final exeFile = Platform.script.path.split('/').last;
    return "Usage: dart bin/$exeFile [command] [arguments?] [...options?]";
  }

  String _removeDashes(String arg) {
    if (arg.startsWith("--")) {
      return arg.substring(2);
    }
    if (arg.startsWith("-")) {
      return arg.substring(1);
    }
    return arg;
  }
}
