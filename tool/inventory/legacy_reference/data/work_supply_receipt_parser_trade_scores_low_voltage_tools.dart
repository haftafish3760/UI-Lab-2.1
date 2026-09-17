part of 'work_supply_receipt_parser.dart';

int _lowVoltageDataReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'low voltage and data') return score;
  if (text.contains('landscape') &&
      RegExp(
        r'\b(path light|spot light|well light|transformer|direct burial)\b',
      ).hasMatch(text)) {
    score -= 32;
  }
  if (RegExp(
    r'\b(cat5e|cat6|cat6a|cat7|ethernet|network cable|data cable|rj45|keystone|coax|rg6|rg59|fiber|low voltage|lv bracket|tester|toner|punchdown|poe camera|'
    r'video doorbell|access control|door contact|hdmi|speaker plate|speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker|'
    r'cable tie|j-hook|smart lock|smart thermostat|smart switch|leak sensor|network rack|rack pdu|rack mount ups|rack ups|cage nut|rack screw|poe splitter|'
    r'poe extender|fiber distribution|smurf tube|flexible raceway|bridle ring|structured media|fiber pigtail|sfp transceiver|alarm battery|electric strike|8k hdmi)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  if (RegExp(
        r'\b(cat5e|cat6|cat6a|ethernet|network cable|data cable)\b',
      ).hasMatch(text) &&
      itemType.contains('network cable')) {
    score += 28;
  }
  for (final rating in ['cat5e', 'cat6a', 'cat7', 'cat6']) {
    if (text.contains(rating)) {
      if (itemName.contains(rating.toLowerCase())) {
        score += 28;
      } else if (itemName.contains('cat')) {
        score -= 18;
      }
    }
  }
  if (RegExp(r'\b(plenum|cmp)\b').hasMatch(text)) {
    if (itemName.contains('plenum') || itemName.contains('cmp')) {
      score += 22;
    } else if (itemType.contains('network cable')) {
      score -= 16;
    }
  }
  if (RegExp(r'\b(coax|rg6|rg59|coaxial)\b').hasMatch(text) &&
      itemName.contains('coax')) {
    score += 26;
  }
  if (RegExp(r'\b(fiber|lc-lc|sc-sc|fiber jumper)\b').hasMatch(text) &&
      itemName.contains('fiber')) {
    score += 26;
  }
  if (RegExp(r'\b(rj45|ethernet plug|mod plug)\b').hasMatch(text) &&
      itemName.contains('rj45')) {
    score += 26;
  }
  if (RegExp(r'\b(keystone|data jack)\b').hasMatch(text) &&
      itemName.contains('keystone')) {
    score += 24;
  }
  if (RegExp(r'\b(patch panel)\b').hasMatch(text) &&
      itemName.contains('patch panel')) {
    score += 24;
  }
  if (RegExp(
        r'\b(low voltage bracket|lv bracket|mud ring|data plate|media enclosure)\b',
      ).hasMatch(text) &&
      category == 'boxes and plates') {
    score += 24;
  }
  if (RegExp(r'\b(low voltage bracket|lv bracket|mud ring)\b').hasMatch(text) &&
      itemName.contains('low voltage mounting bracket')) {
    score += 72;
  }
  if (text.contains('lv bracket') &&
      text.contains('mud ring') &&
      itemName.contains('2 gang low voltage mounting bracket')) {
    score += 110;
  }
  if (RegExp(
        r'\b(hdmi|usb-c|speaker plate|binding post|banana plug)\b',
      ).hasMatch(text) &&
      itemType.contains('av wall')) {
    score += 26;
  }
  for (final connector in ['usb-c', 'hdmi', 'rca']) {
    if (text.contains(connector)) {
      if (itemName.contains(connector)) {
        score += 34;
      } else if (RegExp(
        r'\b(keystone|plate|jack|insert|coupler)\b',
      ).hasMatch(itemName)) {
        score -= 18;
      }
    }
  }
  for (final color in ['white', 'ivory', 'black', 'blue', 'gray']) {
    if (text.contains(color)) {
      if (itemName.contains(color)) {
        score += 22;
      } else if (RegExp(r'\b(keystone|plate|jack|insert)\b').hasMatch(text) &&
          RegExp(r'\b(keystone|plate|jack|insert)\b').hasMatch(itemName)) {
        score -= 12;
      }
    }
  }
  if (RegExp(
        r'\b(hdmi cable|high speed hdmi|in-wall hdmi|usb-c cable|speaker selector|volume control|ir repeater|ir emitter|hdmi extender|usb extender|patch cord|'
        r'ethernet patch cord|speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker)\b',
      ).hasMatch(text) &&
      itemType.contains('av cable')) {
    score += 28;
  }
  if (RegExp(
        r'\b(patch cord|ethernet patch cord|patch cable|speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker|banana plug|hdmi coupler)\b',
      ).hasMatch(text) &&
      itemType.contains('patch cable')) {
    score += 30;
  }
  if (RegExp(r'\b(patch cord|patch cable)\b').hasMatch(text)) {
    if (itemName.contains('patch cord') || itemName.contains('patch cable')) {
      score += 80;
    } else if (itemType.contains('network cable')) {
      score -= 36;
    }
  }
  if (RegExp(
    r'\b(speaker pair|in wall speaker|in-wall speaker|in ceiling speaker|in-ceiling speaker)\b',
  ).hasMatch(text)) {
    if (itemName.contains('speaker pair')) {
      score += 80;
    } else if (itemType.contains('patch cable')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(poe camera|security camera|ip camera|video doorbell|nvr)\b',
      ).hasMatch(text) &&
      itemType.contains('security camera')) {
    score += 30;
  }
  if (RegExp(
    r'\b(video doorbell transformer|doorbell transformer)\b',
  ).hasMatch(text)) {
    if (text.contains('video doorbell') &&
        itemName.contains('doorbell transformer')) {
      score += 76;
    }
  }
  if (RegExp(
        r'\b(camera junction box|camera mount|camera bracket|cctv power supply|doorbell chime|doorbell power kit|doorbell wedge|exit button|no touch exit|request to exit|rex button)\b',
      ).hasMatch(text) &&
      itemType.contains('camera mounts')) {
    score += 30;
  }
  if (RegExp(
        r'\b(door contact|window contact|motion detector|access control|card reader|mag lock|electric strike|no touch exit|exit button)\b',
      ).hasMatch(text) &&
      itemType.contains('access')) {
    score += 30;
  }
  if (RegExp(r'\b(no touch exit button|exit button)\b').hasMatch(text) &&
      itemName.contains('exit button')) {
    score += 70;
  }
  if (RegExp(
        r'\b(smart lock|smart thermostat|smart dimmer|smart switch|smart plug|leak sensor|c-wire adapter|garage door controller|smart hub|smart keypad)\b',
      ).hasMatch(text) &&
      itemType.contains('smart home')) {
    score += 30;
  }
  if (RegExp(r'\b(c-wire adapter|common wire adapter)\b').hasMatch(text)) {
    if (itemName.contains('c-wire adapter')) {
      score += 110;
    } else if (itemName.contains('thermostat') && !itemName.contains('smart')) {
      score -= 24;
    }
  }
  if (RegExp(
        r'\b(tester|toner|tone generator|fox and hound|certifier|vfl)\b',
      ).hasMatch(text) &&
      category == 'testers and tools') {
    score += 24;
  }
  if (RegExp(
        r'\b(punchdown|punch down|rj45 crimper|coax crimper|stripper)\b',
      ).hasMatch(text) &&
      itemType.contains('termination')) {
    score += 24;
  }
  if (RegExp(
        r'\b(cable tie|velcro tie|cable label|wire marker|j-hook|rack)\b',
      ).hasMatch(text) &&
      itemType.contains('cable management')) {
    score += 24;
  }
  if (RegExp(
        r'\b(smurf tube|flexible raceway|cable raceway|bridle ring|cable d-ring|pull string|structured media enclosure|structured media power)\b',
      ).hasMatch(text) &&
      itemType.contains('structured wiring pathway')) {
    score += 42;
  }
  if (RegExp(r'\b(smurf tube|flexible raceway)\b').hasMatch(text)) {
    if (itemName.contains('smurf tube') ||
        itemName.contains('flexible raceway')) {
      score += 56;
    } else if (itemName.contains('cable raceway')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(network rack|wall mount rack|rack shelf|rack pdu|rack power|poe splitter|poe extender|poe injector|fiber distribution|fiber splice tray)\b',
      ).hasMatch(text) &&
      itemType.contains('rack')) {
    score += 28;
  }
  if (RegExp(
        r'\b(slim keystone|fiber pigtail|sfp transceiver|sfp plus transceiver|fiber splice cassette|poe injector|poe splitter|poe extender)\b',
      ).hasMatch(text) &&
      itemType.contains('network fiber')) {
    score += 42;
  }
  if (RegExp(r'\b(sfp transceiver|sfp plus transceiver)\b').hasMatch(text)) {
    if (itemName.contains('sfp')) {
      score += 58;
    } else if (itemName.contains('fiber')) {
      score -= 10;
    }
  }
  if (RegExp(
        r'\b(alarm backup battery|alarm battery|gel filled alarm splice|b connector alarm splice|electric strike|electric door strike|request to exit|card reader|alarm keypad|alarm siren)\b',
      ).hasMatch(text) &&
      itemType.contains('security access')) {
    score += 42;
  }
  if (RegExp(r'\b(alarm backup battery|alarm battery)\b').hasMatch(text)) {
    if (itemName.contains('alarm backup battery')) {
      score += 58;
    }
  }
  if (RegExp(
        r'\b(8k hdmi|active hdmi|optical hdmi|pass through plate|brush pass through|speaker volume control|smart hub|doorbell wedge|doorbell angle mount)\b',
      ).hasMatch(text) &&
      itemType.contains('av smart home')) {
    score += 42;
  }
  if (RegExp(r'\b(8k hdmi|active hdmi|optical hdmi)\b').hasMatch(text)) {
    if (itemName.contains('hdmi')) {
      score += 52;
    }
  }
  if (RegExp(
        r'\b(rack drawer|brush panel|blank panel|rack fan|rack ups|rack mount ups|uninterruptible power supply|cage nut|rack screw|velcro one wrap|velcro wrap)\b',
      ).hasMatch(text) &&
      itemType.contains('rack service')) {
    score += 30;
  }
  if (RegExp(
    r'\b(rack mount ups|rack ups|uninterruptible power supply)\b',
  ).hasMatch(text)) {
    if (itemName.contains('rack mount ups')) {
      score += 80;
    } else if (itemType.contains('cable management')) {
      score -= 24;
    }
  }
  if (RegExp(r'\b(cage nut|rack screw)\b').hasMatch(text)) {
    if (itemName.contains('cage nut') || itemName.contains('rack screw')) {
      score += 80;
    } else if (itemType.contains('cable management')) {
      score -= 8;
    }
  }
  if (RegExp(
    r'\b(romex|breaker|gfci|receptacle|concrete|mulch)\b',
  ).hasMatch(text)) {
    score -= 18;
  }
  return score;
}
