part of 'work_supply_receipt_parser.dart';

int _receiptFallbackSpecificityScore(String text, _ReceiptCatalogEntry entry) {
  final itemName = entry.item.name.toLowerCase();
  final normalizedText = entry.normalizedText;
  var score = 0;
  if (RegExp(r'\b(anode|anode rod)\b').hasMatch(text)) {
    if (itemName.contains('water heater repair part') ||
        normalizedText.contains('anode')) {
      score += 220;
    } else if (itemName.contains('water heater') ||
        normalizedText.contains('water heater')) {
      score -= 24;
    }
  }
  if (RegExp(
    r'\b(heating element|water heater element|element)\b',
  ).hasMatch(text)) {
    if (itemName.contains('water heater repair part') ||
        normalizedText.contains('element')) {
      score += 180;
      if (RegExp(r'\b(4500w|5500w|watt|screw in)\b').hasMatch(text) &&
          normalizedText.contains('element')) {
        score += 260;
      }
    } else if (itemName.contains('water heater') ||
        normalizedText.contains('water heater')) {
      score -= 220;
    }
  }
  if (RegExp(
    r'\b(relief valve|t p relief|t p valve|t and p valve|temperature pressure)\b',
  ).hasMatch(text)) {
    if (itemName.contains('relief valve') ||
        normalizedText.contains('relief valve') ||
        normalizedText.contains('t p relief') ||
        normalizedText.contains('t and p relief')) {
      score += 200;
    } else if (itemName.contains('water heater repair part') ||
        normalizedText.contains('water heater')) {
      score -= 26;
    }
  }
  if (RegExp(r'\b(vac relief|vacuum relief|wh vacuum)\b').hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (itemName.contains('vacuum relief') ||
            normalizedText.contains('vacuum relief'))) {
      score += 260;
    } else if (entry.item.trade == 'Plumbing' &&
        (itemName.contains('temperature and pressure') ||
            normalizedText.contains('t p relief') ||
            normalizedText.contains('relief valve'))) {
      score -= 150;
    }
  }
  if (RegExp(r'\bpvc\b').hasMatch(text) &&
      RegExp(r'\b(cement|solvent\s+cement|glue)\b').hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' && itemName.contains('pvc cement')) {
      score += 420;
      final amount = _receiptPackageAmount(text, 'oz');
      if (_itemMatchesPackageAmount(entry.item, amount, 'oz')) score += 180;
    } else if (entry.item.trade == 'Plumbing' &&
        (itemName.contains('pvc schedule 40') ||
            itemName.contains('pvc dwv'))) {
      score -= 260;
    }
  }
  if (RegExp(
    r'\b(hose bibb? vac|hose bibb? vacuum|hose bibb? vac brkr|vac brkr|vacuum breaker)\b',
  ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('vacuum breaker') ||
            normalizedText.contains('hose bibb vacuum'))) {
      score += 280;
    } else if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('hose bibb') &&
        !normalizedText.contains('vacuum')) {
      score -= 180;
    }
  }
  if (RegExp(
    r'\b(faucet conn|faucet connector|lav conn|braided connector|braided supply)\b',
  ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('faucet connector') ||
            normalizedText.contains('supply connector') ||
            normalizedText.contains('braided'))) {
      score += 260;
    } else if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('hose bibb')) {
      score -= 220;
    }
  }
  if (RegExp(
    r'\b(sink repair kit|lavatory repair kit|basin repair kit|'
    r'kit reparacion lavabo|kit reparacion fregadero)\b',
  ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('sink repair kit')) {
      score += 360;
    } else if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('faucet o-ring') ||
            normalizedText.contains('faucet repair kit') ||
            normalizedText.contains('seat washer kit'))) {
      score -= 180;
    }
  }
  if (RegExp(
    r'\b(faucet repair kit|o-ring and seat kit|o ring and seat kit|'
    r'kit reparacion llave|kit reparacion grifo)\b',
  ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('faucet o-ring') ||
            normalizedText.contains('faucet repair kit'))) {
      score += 240;
    } else if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('sink repair kit')) {
      score -= 160;
    }
  }
  if (RegExp(
    r'\b(stat wire|thermostat wire|low voltage wire)\b',
  ).hasMatch(text)) {
    if (itemName.contains('thermostat wire') ||
        normalizedText.contains('thermostat wire') ||
        normalizedText.contains('stat wire') ||
        normalizedText.contains('low voltage wire')) {
      score += 220;
    } else if (normalizedText.contains('water heater') ||
        itemName.contains('water heater repair part')) {
      score -= 80;
    }
  }
  if (RegExp(
    r'\b(threaded rod|thread rod|all thread|all-thread|allthread)\b',
  ).hasMatch(text)) {
    if (normalizedText.contains('threaded rod') ||
        normalizedText.contains('all thread') ||
        normalizedText.contains('rod stock')) {
      score += 260;
    } else if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('hanger') ||
            normalizedText.contains('pipe support'))) {
      score -= 80;
    }
  }
  if (RegExp(
    r'\b(sheet metal screw|zip screw|tek screw|self drilling screw|self tapping screw|sms)\b',
  ).hasMatch(text)) {
    if (normalizedText.contains('sheet metal screw') ||
        normalizedText.contains('zip screw') ||
        normalizedText.contains('tek screw') ||
        normalizedText.contains('self drilling screw')) {
      score += 280;
      if (text.contains('100 pack') && normalizedText.contains('100 pack')) {
        score += 60;
      }
    } else if (!normalizedText.contains('screw')) {
      score -= 360;
    }
  }
  if (RegExp(
    r'\b(tapcon|concrete screw|masonry screw|concrete anchor screw|blue screw)\b',
  ).hasMatch(text)) {
    if (normalizedText.contains('concrete screw anchor') ||
        normalizedText.contains('tapcon') ||
        normalizedText.contains('masonry screw')) {
      score += 240;
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(90|ell|elb|elbow|90d|90 deg|90 degree)\b').hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('pex') &&
        (normalizedText.contains('90') ||
            normalizedText.contains('elbow') ||
            normalizedText.contains('ell'))) {
      score += 520;
      if (RegExp(r'\b(crimp|brass)\b').hasMatch(text) &&
          (normalizedText.contains('crimp') ||
              normalizedText.contains('pex'))) {
        score += 180;
      }
    } else if (entry.item.trade == 'Plumbing' &&
        !normalizedText.contains('pex')) {
      score -= 260;
      if (normalizedText.contains('brass') ||
          normalizedText.contains('copper') ||
          normalizedText.contains('pvc') ||
          normalizedText.contains('cpvc')) {
        score -= 140;
      }
    }
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(tee|t|red tee|reducing tee)\b').hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('pex') &&
        normalizedText.contains('tee')) {
      score += 240;
      if (RegExp(r'\b(red|reducing)\b').hasMatch(text) &&
          normalizedText.contains('reducing')) {
        score += 54;
      }
    } else if (entry.item.trade != 'Plumbing') {
      score -= 80;
    }
  }
  if (RegExp(r'\b(pvc|sch40|s40|schedule 40)\b').hasMatch(text) &&
      RegExp(
        r'\b(coupling|coup|cplg|coupler|red coup|reducing coupling)\b',
      ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('pvc schedule 40') &&
        normalizedText.contains('coupling')) {
      score += 230;
      if (RegExp(r'\b(red|reducer|reducing)\b').hasMatch(text) &&
          normalizedText.contains('reducing')) {
        score += 64;
      }
    } else if (entry.item.trade != 'Plumbing') {
      score -= 80;
    }
  }
  if (RegExp(
    r'\b(s/j|sj|slip joint|slip nut|slip washer|trap washer)\b',
  ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('slip joint') ||
            normalizedText.contains('slip nut') ||
            normalizedText.contains('slip washer') ||
            normalizedText.contains('trap washer'))) {
      score += 230;
      if (RegExp(r'\b(nut|washer)\b').hasMatch(text)) score += 42;
    } else if (entry.item.trade != 'Plumbing') {
      score -= 90;
    }
  }
  if (RegExp(
    r'\b(desanco|marvel|trap adpt|trap adapt|trap adapter|trap adaptor)\b',
  ).hasMatch(text)) {
    if (RegExp(r'\b(abs|black drain|black dwv)\b').hasMatch(text) &&
        entry.item.trade == 'Plumbing') {
      if (normalizedText.contains('abs dwv') &&
          normalizedText.contains('trap adapter')) {
        score += 320;
      } else if (normalizedText.contains('tubular drain adapter')) {
        score -= 180;
      }
    }
    if (entry.item.trade == 'Plumbing' &&
        normalizedText.contains('tubular drain adapter')) {
      score += 190;
      if (text.contains('desanco') && itemName.contains('desanco')) {
        score += 240;
      } else if (text.contains('desanco') && !itemName.contains('desanco')) {
        score -= 120;
      }
      if (text.contains('marvel') && itemName.contains('marvel')) {
        score += 240;
      } else if (text.contains('marvel') && !itemName.contains('marvel')) {
        score -= 120;
      }
      if (RegExp(r'\b(compression|comp)\b').hasMatch(text) &&
          normalizedText.contains('compression')) {
        score += 70;
      }
    } else if (entry.item.trade != 'Plumbing') {
      score -= 70;
    }
  }
  if (RegExp(
    r'\b(tubular|tubular drain|slip joint adapter|drain adapter)\b',
  ).hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('tubular drain adapter') ||
            normalizedText.contains('tubular') &&
                normalizedText.contains('adapter'))) {
      score += 260;
    } else if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('slip joint nut') ||
            normalizedText.contains('slip joint washer') ||
            normalizedText.contains('nut and washer'))) {
      score -= 190;
    }
  }
  if (RegExp(r'\b(ptfe|thread tape|teflon tape)\b').hasMatch(text)) {
    if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('thread tape') ||
            normalizedText.contains('ptfe tape') ||
            normalizedText.contains('tape'))) {
      score += 280;
    } else if (entry.item.trade == 'Plumbing' &&
        (normalizedText.contains('compound') ||
            normalizedText.contains('pipe joint compound') ||
            normalizedText.contains('pipe dope'))) {
      score -= 220;
    }
  }
  if (RegExp(
    r'\b(cleanout|clean out|co plug|c/o plug|countersunk|raised head)\b',
  ).hasMatch(text)) {
    if (RegExp(r'\b(cover|plate)\b').hasMatch(text)) {
      if (entry.item.trade == 'Plumbing' &&
          (normalizedText.contains('cleanout cover') ||
              normalizedText.contains('cover') ||
              normalizedText.contains('plate'))) {
        score += 260;
      } else if (entry.item.trade == 'Plumbing' &&
          normalizedText.contains('plug')) {
        score -= 220;
      }
    }
    if (entry.item.trade == 'Plumbing' &&
        (itemName.contains('cleanout access part') ||
            normalizedText.contains('cleanout plug') ||
            normalizedText.contains('clean out plug'))) {
      score += 220;
      if (text.contains('countersunk') &&
          normalizedText.contains('countersunk')) {
        score += 80;
      }
      if (text.contains('brass') && normalizedText.contains('brass')) {
        score += 60;
      }
    } else if (entry.item.trade == 'Plumbing' &&
        (itemName.contains('cap') || itemName.contains('plug'))) {
      score -= 120;
    } else if (entry.item.trade != 'Plumbing') {
      score -= 80;
    }
  }
  if (RegExp(r'\b(float switch|piggyback|pump float)\b').hasMatch(text)) {
    if (itemName.contains('pump control part') ||
        normalizedText.contains('float switch') ||
        normalizedText.contains('piggyback')) {
      score += 190;
    } else if (itemName.contains('sump pump')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(high water alarm|pump alarm)\b').hasMatch(text)) {
    if (itemName.contains('pump control part') ||
        normalizedText.contains('high water alarm') ||
        normalizedText.contains('pump alarm')) {
      score += 210;
    } else if (itemName.contains('sump pump')) {
      score -= 22;
    }
  }
  return score;
}
