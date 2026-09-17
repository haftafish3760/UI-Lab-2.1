part of 'work_supply_receipt_parser.dart';

int _toolsSafetyReceiptScore(
  String text,
  String trade,
  String category,
  WorkSupplyItem item,
) {
  var score = 0;
  if (trade != 'tools and safety') return score;
  if (RegExp(
    r'\b(wrench|pliers|screwdriver|utility knife|saw blade|drill bit|gloves|safety glasses|n95|mask|tape measure|level|chalk line|duct tape|shop towels|'
    r'trash bags|extension cord|work light|ladder|drop cloth|tarp|marking paint|bar clamp|tool bag|box fan|jobsite heater|fish tape|pipe wrench|pex crimp|'
    r'drain auger|pressure gauge|thermal camera|torque wrench|rivet gun|staple gun|pipe threading die|closet auger|basin wrench|emt bender|pull string|'
    r'breaker finder|wire stripper|roofing shovel|safety harness|roof anchor|lifeline|hepa filter|hepa vac|vac filter|dust shroud)\b',
  ).hasMatch(text)) {
    score += 16;
  }
  final itemType = item.itemType.toLowerCase();
  final itemName = item.name.toLowerCase();
  if (RegExp(
        r'\b(adjustable wrench|crescent wrench|pliers|screwdriver|utility knife|hammer|pry bar)\b',
      ).hasMatch(text) &&
      itemType.contains('hand tools')) {
    score += 26;
  }
  if (RegExp(
        r'\b(saw blade|drill bit|driver bit|oscillating|reciprocating|razor blade|knife blade)\b',
      ).hasMatch(text) &&
      itemType.contains('saw blades')) {
    score += 26;
  }
  if (RegExp(
        r'\b(sds plus masonry bit set|masonry bit set|drill bit set)\b',
      ).hasMatch(text) &&
      itemType.contains('saw blades')) {
    score += 72;
  }
  if (text.contains('sds plus') && itemName.contains('sds plus')) {
    score += 90;
  } else if (text.contains('sds plus') &&
      itemName.contains('masonry bit set')) {
    score -= 90;
  }
  if (RegExp(
        r'\b(nitrile gloves|work gloves|cut resistant glove|cut resistant gloves|safety glasses|n95|dust mask|respirator|hard hat|ear plug)\b',
      ).hasMatch(text) &&
      category == 'safety') {
    score += 28;
  }
  if (RegExp(
        r'\b(cut resistant glove|cut resistant gloves)\b',
      ).hasMatch(text) &&
      itemName.contains('cut resistant glove')) {
    score += 64;
  }
  for (final size in ['m', 'l', 'xl', '2xl']) {
    if (RegExp('\\b$size\\b').hasMatch(text) && itemName.contains('$size ')) {
      score += 12;
    }
  }
  if (RegExp(
        r'\b(tape measure|level|laser level|chalk line|snap line|marker|pencil|marking paint)\b',
      ).hasMatch(text) &&
      category == 'measuring and layout') {
    score += 26;
  }
  if (text.contains('marking paint') && itemName.contains('marking paint')) {
    score += 34;
  }
  if (RegExp(
        r'\b(duct tape|masking tape|painter tape|construction adhesive|threadlocker)\b',
      ).hasMatch(text) &&
      itemType.contains('tapes')) {
    score += 24;
  }
  if (RegExp(
        r'\b(shop towels|rags|trash bags|demo bags|bucket|broom|degreaser)\b',
      ).hasMatch(text) &&
      itemType.contains('cleaning')) {
    score += 24;
  }
  if (RegExp(
        r'\b(drop cloth|poly tarp|plastic sheeting|floor protection)\b',
      ).hasMatch(text) &&
      itemType.contains('temporary')) {
    score += 26;
  }
  if (text.contains('poly tarp') && itemName.contains('poly tarp')) {
    score += 32;
  }
  if (RegExp(
        r'\b(extension cord|cord reel|gfci cord|work light|headlamp)\b',
      ).hasMatch(text) &&
      itemType.contains('jobsite power')) {
    score += 26;
  }
  if (RegExp(
        r'\b(step ladder|extension ladder|sawhorse|work platform)\b',
      ).hasMatch(text) &&
      itemType.contains('access')) {
    score += 26;
  }
  if (RegExp(
        r'\b(bar clamp|c-clamp|quick clamp|tool bag|parts organizer)\b',
      ).hasMatch(text) &&
      itemType.contains('tool support')) {
    score += 24;
  }
  if (RegExp(
        r'\b(fish tape|pipe wrench|pex crimp|pex clamp|pex expansion tool|pex ring cutter|drain auger|pressure gauge|manifold gauge|leak detector|'
        r'thermal camera|moisture meter|torque screwdriver|torque wrench|breaker finder|stud sensor|grout float|margin trowel|shingle gauge|siding removal)\b',
      ).hasMatch(text) &&
      itemType.contains('specialty trade')) {
    score += 28;
  }
  if (RegExp(
        r'\b(pipe threading die|threading die|pipe threader|closet auger|toilet auger|basin wrench|sink wrench|pex ring cutter|crimp ring cutter|pvc cutter|snap cutter|tub drain wrench)\b',
      ).hasMatch(text) &&
      itemType.contains('pipe plumbing')) {
    score += 34;
  }
  if (RegExp(r'\b(pipe threading die|threading die)\b').hasMatch(text)) {
    if (itemName.contains('pipe threading die')) {
      score += 70;
    } else if (itemName.contains('pipe wrench')) {
      score -= 18;
    }
  }
  if (RegExp(
        r'\b(emt bender|conduit bender|pull string|pull line|fish rod|glow rod|breaker finder|circuit tracer|wire stripper|cable ripper|mc cable cutter|conduit reamer|wire marker)\b',
      ).hasMatch(text) &&
      itemType.contains('electrical test')) {
    score += 34;
  }
  if (RegExp(r'\b(emt bender|conduit bender)\b').hasMatch(text)) {
    if (itemName.contains('emt bender')) {
      score += 70;
    } else if (itemName.contains('conduit')) {
      score += 20;
    }
  }
  if (RegExp(
        r'\b(concrete trowel|concrete finishing trowel|magnesium hand float|notched trowel|tile trowel|grout float|roofing shovel|tear off shovel|shingle remover|roofing hatchet)\b',
      ).hasMatch(text) &&
      itemType.contains('concrete masonry')) {
    score += 34;
  }
  if (RegExp(
    r'\b(taping knife|drywall knife|mud pan|drywall mud pan)\b',
  ).hasMatch(text)) {
    score -= 22;
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(r'\b(crimp|clamp)\b').hasMatch(text) &&
      itemName.contains('pex')) {
    score += 80;
  }
  if (RegExp(r'\bpex\b').hasMatch(text) &&
      RegExp(
        r'\b(expansion tool|tool head|ring cutter|crimp|clamp)\b',
      ).hasMatch(text) &&
      itemName.contains('pex') &&
      RegExp(r'\b(tool|head|cutter)\b').hasMatch(itemName)) {
    score += 90;
  }
  for (final pexTool in ['expansion tool head', 'clamp tool', 'crimp tool']) {
    final receiptTerm = pexTool == 'expansion tool head'
        ? 'expansion tool'
        : pexTool;
    if (text.contains(receiptTerm)) {
      if (itemName.contains(pexTool)) {
        score += 70;
      } else if (itemName.contains('pex') && itemName.contains('tool')) {
        score -= 30;
      }
    }
  }
  if (RegExp(
        r'\b(screw setter|nut setter|tile bit|masonry bit|hinge bit|rivet gun|staple gun|powder actuated|powder load|concrete nail driver)\b',
      ).hasMatch(text) &&
      itemType.contains('fastener anchor')) {
    score += 28;
  }
  if (RegExp(r'\b(screw setter|setter bit)\b').hasMatch(text) &&
      itemName.contains('screw setter')) {
    score += 80;
  }
  if (text.contains('bar clamp') && itemName.contains('bar clamp')) {
    score += 36;
  }
  if (RegExp(
        r'\b(box fan|drum fan|air mover|jobsite heater|propane heater)\b',
      ).hasMatch(text) &&
      itemType.contains('temporary jobsite')) {
    score += 24;
  }
  if (RegExp(
        r'\b(spill kit|absorbent pad|oil dry|lockout|safety harness|roof anchor)\b',
      ).hasMatch(text) &&
      itemType.contains('spill')) {
    score += 24;
  }
  if (RegExp(
        r'\b(safety harness|roof anchor|fall protection|roof safety kit|lifeline|lanyard|rope grab|self retracting lifeline)\b',
      ).hasMatch(text) &&
      itemType.contains('fall protection')) {
    score += 36;
  }
  if (RegExp(r'\b(roof safety kit|fall protection kit)\b').hasMatch(text)) {
    if (itemName.contains('roof safety kit') ||
        itemName.contains('harness and lanyard')) {
      score += 50;
    }
  }
  if (RegExp(
        r'\b(hepa filter|hepa vac filter|vac filter|vacuum filter|dust bag|dust collection bag|dust shroud|shop vac hose|shop vacuum hose|dust extractor|vacuum hose)\b',
      ).hasMatch(text) &&
      itemType.contains('dust control')) {
    score += 36;
  }
  if (RegExp(
    r'\b(hepa filter|hepa vac filter|vac filter|dust extractor hepa)\b',
  ).hasMatch(text)) {
    if (itemName.contains('hepa')) {
      score += 70;
    } else if (itemName.contains('shop towels')) {
      score -= 20;
    }
  }
  if (RegExp(r'\b(n95|dust mask)\b').hasMatch(text)) {
    if (itemName.contains('n95') || itemName.contains('dust mask')) {
      score += 24;
    } else if (category == 'safety') {
      score -= 10;
    }
  }
  if (RegExp(r'\b(7-1/4|6-1/2|10 in)\b').hasMatch(text) &&
      itemName.contains('saw blade')) {
    if (_containsExactPhrase(text, item.variant)) score += 20;
  }
  if (RegExp(
    r'\b(cat6|rj45|coax|thinset|concrete mix|mulch)\b',
  ).hasMatch(text)) {
    score -= 18;
  }
  return score;
}
