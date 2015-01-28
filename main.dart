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
Plugin plugin;

void main(args, port) {
  plugin = polymorphic(args, port);
  
  print("[Administration] Loading Plugin");

  bot = plugin.getBot();

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
    bot.sendRawLine(event.network, line);
  }

  for (var cmd in MODE_COMMANDS.keys) {
    bot.command(cmd, (event) {
      if (event.args.length != 1) {
        event.reply(usageFor(event.command));
      } else {
        raw(event, "MODE ${event.channel} ${MODE_COMMANDS[event.command]} ${event.args[0]}");
      }
    }, permission: cmd);
  }

  bot.command("topic", (event) {
    if (event.args.length == 0) {
      event.reply(usageFor(event.command));
    } else {
      raw(event, "TOPIC ${event.channel} :${event.args.join(" ")}");
    }
  }, permission: "topic");

  bot.command("cycle", (event) {
    if (event.args.isNotEmpty) {
      event.reply("> Usage: cycle");
      return;
    }
    
    var network = event.network;
    var channel = event.channel;

    bot.partChannel(network, channel);
    bot.joinChannel(network, channel);
  }, permission: "command.cycle");

  bot.command("kick", (event) {
    if (event.args.length != 1) {
      event.reply(usageFor(event.command));
    } else {
      raw(event, "KICK ${event.channel} ${event.args[0]}");
    }
  }, permission: "kick");

  bot.command("stop", (event) {
    bot.stop();
  }, permission: "bot.stop");

  bot.command("list-networks", (event) {
    if (event.args.isNotEmpty) {
      event.reply("> Usage: list-networks");
      return;
    }

    bot.getNetworks().then((networks) {
      event.reply("> Networks: ${networks.join(" ")}");
    });
  }, permission: "networks.list");

  bot.command("join", (event) {
    if (event.args.length > 2 || event.args.isEmpty) {
      event.reply("> Usage: join [network] <channel>");
      return;
    }

    var network = event.args.length == 2 ? event.args[0] : event.network;
    var channel = event.args.length == 2 ? event.args[1] : event.args[0];

    bot.joinChannel(network, channel);
  }, permission: "join");

  bot.command("part", (event) {
    if (event.args.length > 2 || event.args.isEmpty) {
      event.reply("> Usage: part [network] <channel>");
      return;
    }

    var network = event.args.length == 2 ? event.args[0] : event.network;
    var channel = event.args.length == 2 ? event.args[1] : event.args[0];

    bot.partChannel(network, channel);
  }, permission: "part");
}
