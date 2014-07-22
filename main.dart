import 'package:plugins/plugin.dart';
import 'dart:isolate';

Receiver recv;

Map<String, String> mode_commands = {
  "op": "+o",
  "deop": "-o",
  "voice": "+v",
  "devoice": "-v",
  "quiet": "+q",
  "unquiet": "-q",
  "ban": "+b",
  "unban": "-b"
};

void main(List<String> args, SendPort port) {
  print("[Channel Admin] Loading");
  recv = new Receiver(port);

  recv.listen((data) {
    if (data["event"] == "command") {
      handle_command(data);
    }
  });
}

String usageFor(String command) {
  String actual() {
    if (mode_commands.containsKey(command)) {
      return "<user>";
    }
    switch (command) {
      case "topic":
        return "<message>";
      case "kick":
        return "<user>";
      default:
        return "";
    }
  }
  var usage = actual();
  return "> Usage: ${command}" + (usage.isNotEmpty ? " " + usage : "");
}

void handle_command(data) {
  void send(String command, Map<String, dynamic> args) {
    var msg = {
      "network": data['network'],
      "command": command
    };
    msg.addAll(args);
    recv.send(msg);
  }
  
  void raw(String line) => send("raw", { "line": line });
  
  void reply(String message) {
    send("message", {
      "target": data["target"],
      "message": message
    });
  }
  
  var command = data['command'] as String;
  var target = data['target'] as String;
  var network = data['network'];
  var args = data['args'] as List<String>;

  if (mode_commands.containsKey(command)) {
    if (args.length != 1) {
      reply(usageFor(command));
    } else {
      raw("MODE ${target} ${mode_commands[command]} ${args[0]}");
    }
    return;
  }
  
  switch (command) {
    case "topic":
      if (args.length == 0) {
        reply(usageFor(command));
      } else {
        raw("TOPIC ${target} :${args.join(" ")}"); 
      }
      break;
    case "kick":
      if (args.length != 1) {
        reply(usageFor(command));
      } else {
        raw("KICK ${target} ${args[0]}"); 
      }
      break;
    case "list-networks":
      recv.get("networks", {}).then((response) {
        reply("> Networks: " + response['networks'].join(", "));
      });
      break;
  }
}