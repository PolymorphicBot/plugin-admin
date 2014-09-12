import 'package:plugins/plugin.dart';
import 'dart:isolate';
import 'dart:io';

Receiver recv;

final Map<String, String> MODE_COMMANDS = {
  "op": "+o",
  "deop": "-o",
  "voice": "+v",
  "devoice": "-v",
  "quiet": "+q",
  "unquiet": "-q",
  "ban": "+b",
  "unban": "-b"
};

Function onDisconnect;

void main(List<String> args, SendPort port) {
  print("[Channel Admin] Loading");
  recv = new Receiver(port);

  recv.listen((data) {
    switch (data['event']) {
      case "disconnect":
        if (onDisconnect != null) {
          onDisconnect();
        }
        break;
      case "command":
        handleCommand(data);
        break;
    }
  });
}

String usageFor(String command) {
  String actual() {
    if (MODE_COMMANDS.containsKey(command)) {
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

void permission(void callback(Map data), String network, String target, String user, String node, [bool notify]) {
  Map params = {
    "node": node,
    "network": network,
    "nick": user,
    "target": target,
    "notify": notify
  };
  recv.get("permission", params).callIf((data) => data['has']).then(callback);
}

final List<String> POSSIBLE = ["topic", "kick", "stop", "list-networks"]..addAll(MODE_COMMANDS.keys);

void handleCommand(data) {
  var network = data['network'] as String;
  var user = data['from'] as String;
  var target = data['target'] as String;
  var command = data['command'] as String;
  var args = data['args'] as List<String>;

  void require(String perm, void handle()) {
    permission((it) => handle(), network, target, user, perm);
  }

  void send(String command, Map<String, dynamic> args) {
    var msg = {
      "network": data['network'],
      "command": command
    };
    msg.addAll(args);
    recv.send(msg);
  }

  void raw(String line) => send("raw", {
    "line": line
  });

  void reply(String message) {
    send("message", {
      "target": data["target"],
      "message": message
    });
  }

  if (POSSIBLE.contains(command)) {
    require(command, () {
      if (MODE_COMMANDS.containsKey(command)) {
        if (args.length != 1) {
          reply(usageFor(command));
        } else {
          raw("MODE ${target} ${MODE_COMMANDS[command]} ${args[0]}");
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
        case "stop":
          send("stop-bot", {});
          break;
        case "list-networks":
          recv.get("networks", {}).then((response) {
            reply("> Networks: " + response['networks'].join(", "));
          });
          break;
      }
    });
  }
}
