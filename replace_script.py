import re

file_path = r"c:\Users\Kean\OneDrive\Desktop\rockies-fitness-tracker\Fitness-Tracker-app\lib\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

reps_target = """                                              Expanded(
                                                child: TextField(
                                                  controller: repsController,
                                                  enabled: !widget.isReadOnlyMode,
                                                  readOnly: widget.isReadOnlyMode,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Reps',
                                                        helperText:
                                                            'Whole numbers only',
                                                        helperStyle: TextStyle(
                                                          color: Colors.white54,
                                                        ),
                                                        labelStyle: TextStyle(
                                                          color: Colors.orange,
                                                        ),
                                                        border:
                                                            OutlineInputBorder(),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .orange,
                                                                  ),
                                                            ),
                                                      ),
                                                ),
                                              ),"""

reps_replacement = """                                              Expanded(
                                                child: _buildPremiumTextField(
                                                  controller: repsController,
                                                  labelText: 'Reps',
                                                  helperText: 'Whole numbers only',
                                                ),
                                              ),"""

sets_target = """                                              Expanded(
                                                child: TextField(
                                                  controller: setsController,
                                                  enabled: !widget.isReadOnlyMode,
                                                  readOnly: widget.isReadOnlyMode,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'Sets',
                                                        helperText:
                                                            'Whole numbers only',
                                                        helperStyle: TextStyle(
                                                          color: Colors.white54,
                                                        ),
                                                        labelStyle: TextStyle(
                                                          color: Colors.orange,
                                                        ),
                                                        border:
                                                            OutlineInputBorder(),
                                                        focusedBorder:
                                                            OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color: Colors
                                                                        .orange,
                                                                  ),
                                                            ),
                                                      ),
                                                ),
                                              ),"""

sets_replacement = """                                              Expanded(
                                                child: _buildPremiumTextField(
                                                  controller: setsController,
                                                  labelText: 'Sets',
                                                  helperText: 'Whole numbers only',
                                                ),
                                              ),"""

# Strip out trailing whitespace for robust replacing
def normalize(s):
    return re.sub(r'[ \t]+\n', '\n', s)

content_norm = normalize(content)
reps_target_norm = normalize(reps_target)
sets_target_norm = normalize(sets_target)

if reps_target_norm in content_norm:
    content_norm = content_norm.replace(reps_target_norm, reps_replacement)
    print("Replaced reps!")
else:
    print("Could not find reps target")

if sets_target_norm in content_norm:
    content_norm = content_norm.replace(sets_target_norm, sets_replacement)
    print("Replaced sets!")
else:
    print("Could not find sets target")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content_norm)
