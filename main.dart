import "package:polymorphic_bot/api.dart";

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

BotConnector bot;
EventManager eventManager;

void main(List<String> args, port) {
  print("[Administration] Loading Plugin");
  
  bot = new BotConnector(port);
  eventManager = bot.createEventManager();
  
  registerCommands();
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

void registerCommands() {

  void raw(CommandEvent event, String line) {
    bot.send("raw", {
      "network": event.network,
      "line": line
    });
  }
  
  for (var cmd in MODE_COMMANDS.keys) {
    eventManager.command(cmd, (event) {
      if (event.args.length != 1) {
        event.reply(usageFor(event.command));
      } else {
        raw(event, "MODE ${event.channel} ${MODE_COMMANDS[event.command]} ${event.args[0]}");
      }
    });
  }
  
  eventManager.command("topic", (event) {
    event.require("topic", () {
      if (event.args.length == 0) {
        event.reply(usageFor(event.command));
      } else {
        raw(event, "TOPIC ${event.channel} :${event.args.join(" ")}");
      }
    });
  });

  eventManager.command("cycle", (event) {
    event.require("command.cycle", () {
      if (event.args.isNotEmpty) {
        event.reply("> Usage: cycle");
        return;
      }

      bot.send("part", {
        "network": event.network,
        "channel": event.channel
      });

      bot.send("join", {
        "network": event.network,
        "channel": event.channel
      });
    });
  });
  
  eventManager.command("kick", (event) {
    event.require("kick", () {
      if (event.args.length != 1) {
        event.reply(usageFor(event.command));
      } else {
        raw(event, "KICK ${event.channel} ${event.args[0]}");
      }
    });
  });
  
  eventManager.command("stop", (event) {
    event.require("bot.stop", () {
      bot.send("stop-bot", {
        "network": event.network
      });
    });
  });
  
  eventManager.command("list-networks", (event) {
    event.require("list-networks", () {
      if (event.args.isNotEmpty) {
        event.reply("> Usage: list-networks");
        return;
      }

      bot.getNetworks().then((networks) {
        event.reply("> Networks: ${networks.join(" ")}");
      });
    });
  });

  eventManager.command("reload", (event) {
    event.require("plugins.reload", () {
      event.reply("> Reloading Plugins");
      bot.send("reload-plugins", {
        "network": event.network
      });
    });
  });

  eventManager.command("join", (event) {
    event.require("join", () {
      if (event.args.length > 2 || event.args.isEmpty) {
        event.reply("> Usage: join [network] <channel>");
        return;
      }

      var network = event.args.length == 2 ? event.args[0] : event.network;
      var channel = event.args.length == 2 ? event.args[1] : event.args[0];

      bot.send("join", {
        "network": network,
        "channel": channel
      });
    });
  });

  eventManager.command("part", (event) {
    event.require("part", () {
      if (event.args.length > 2 || event.args.isEmpty) {
        event.reply("> Usage: part [network] <channel>");
        return;
      }

      var network = event.args.length == 2 ? event.args[0] : event.network;
      var channel = event.args.length == 2 ? event.args[1] : event.args[0];

      bot.send("part", {
        "network": network,
        "channel": channel
      });
    });
  });
}
