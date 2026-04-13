class ArgumentException extends FormatException {
  /// The command that was parsed before the error happened
  ///
  /// This will be empty if the error was on the root server
  final String? command;

  /// The argument that was parsed before the error happened
  final String? argumentName;

  ArgumentException(
    super.message, [
    this.command,
    this.argumentName,
    super.source,
    super.offset,
  ]);

  @override
  String toString() {
    return "ArgumentException: $message";
  }
}
