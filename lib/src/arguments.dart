import 'dart:async';
import 'dart:collection';
import '../command_runner.dart';

enum OptionType { flag, option }

abstract class Argument {
  String get name; // name of the argument
  String? get help; // help text for the argument

  Object? get defaultValue; // default value for the argument
  String? get valueHelp; // optional help text for the value of the argument

  String get usage; // usage example for the argument
}

class Option extends Argument {
  Option(
    this.name, {
    required this.type,
    this.abbr,
    this.help,
    this.defaultValue,
    this.valueHelp,
  });

  final OptionType type;
  final String? abbr;

  @override
  final String name;

  @override
  final String? help;

  @override
  final Object? defaultValue;

  @override
  final String? valueHelp;

  @override
  String get usage {
    if (abbr != null) {
      return "-$abbr, --$name";
    }
    return "--$name";
  }
}

abstract class Command extends Argument {
  String get description;
  bool get requiresArgument => false;
  late CommandRunner runner;

  @override
  String get name;

  @override
  String? get help;

  @override
  Object? get defaultValue;

  @override
  String? get valueHelp;

  final List<Option> _options = [];

  UnmodifiableSetView<Option> get options =>
      UnmodifiableSetView(_options.toSet());

  // A flag is an [Option] that's treated as a boolean.
  void addFlag(String name, {String? help, String? abbr, String? valueHelp}) {
    _options.add(
      Option(
        name,
        help: help,
        abbr: abbr,
        defaultValue: false,
        valueHelp: valueHelp,
        type: OptionType.flag,
      ),
    );
  }

  // An option is an [Option] that takes a value.
  void addOption(
    String name, {
    String? help,
    String? abbr,
    String? defaultValue,
    String? valueHelp,
  }) {
    _options.add(
      Option(
        name,
        help: help,
        abbr: abbr,
        defaultValue: defaultValue,
        valueHelp: valueHelp,
        type: OptionType.option,
      ),
    );
  }

  FutureOr<Object?> run(ArgResults args);

  @override
  String get usage {
    return "$name: $description";
  }
}

class ArgResults {
  Command? command;
  String? commandArg;
  Map<Option, Object?> options = {};

  // Returns true if the flag exists.
  bool flag(String name) {
    // Only check flags, because we're sure that flags are booleans.
    for (var option in options.keys.where(
      (option) => option.type == OptionType.flag,
    )) {
      if (option.name == name) {
        return options[option] as bool;
      }
    }
    return false;
  }

  bool hasOption(String name) {
    return options.keys.any((option) => option.name == name);
  }

  ({Option option, Object? input}) getOption(String name) {
    var mapEntry = options.entries.firstWhere(
      (entry) => entry.key.name == name || entry.key.abbr == name,
    );

    return (option: mapEntry.key, input: mapEntry.value);
  }
}
