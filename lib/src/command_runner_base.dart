import 'dart:collection';
import 'dart:io';
import 'arguments.dart';

class CommandRunner {
  final Map<String, Command> _commands = {};

  UnmodifiableSetView<Command> get commands =>
      UnmodifiableSetView({..._commands.values});

  Future<void> run(List<String> args) async {
    final ArgResults results = parse(args);
    if (results.command != null) {
      Object? output = await results.command!.run(results);
      print(output.toString());
    }
  }

  ArgResults parse(List<String> args) {
    var results = ArgResults();
    results.command = _commands[args.first];
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
}
