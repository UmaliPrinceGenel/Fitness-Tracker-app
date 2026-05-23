import 'dart:io';

void main() {
  final file = File(r"c:\Users\Kean\OneDrive\Desktop\rockies-fitness-tracker\Fitness-Tracker-app\lib\screens\exercise_detail_screen.dart");
  String content = file.readAsStringSync();

  // Replace divider color
  content = content.replaceAll("color: Colors.white38,", "color: Colors.white10,");

  final actionRowTarget = """  Widget _buildBottomActionRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: widget.exerciseNumber > 1
                ? () async {
                    if (widget.isReadOnlyMode) {
                      await _openExercise(widget.exerciseNumber - 1);
                    } else {
                      await _handleBackNavigation();
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[900],
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Previous",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              int totalExercises = widget.workout.exerciseList.length;

              if (widget.isReadOnlyMode) {
                if (widget.exerciseNumber < totalExercises) {
                  await _openExercise(widget.exerciseNumber + 1);
                } else if (mounted) {
                  Navigator.pop(context);
                }
                return;
              }

              if (!await _validateTrackingInputs()) {
                return;
              }

              _markExerciseAsViewed();
              _notifyValidWeightInput();

              // For the last exercise, don't save automatically when pressing "Done"
              if (widget.exerciseNumber < totalExercises) {
                // Save before navigating to next exercise
                await _saveExerciseRecord();
                await _openExercise(widget.exerciseNumber + 1);
              } else {
                // This is the last exercise, so just go back to workout detail screen
                // The workout will be saved when the user presses the "Done" button on the workout screen
                await _saveExerciseRecord();
                Navigator.pop(context); // Go back to workout detail screen
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.isReadOnlyMode
                  ? (widget.exerciseNumber < widget.workout.exerciseList.length
                        ? "Next"
                        : "Back")
                  : widget.exerciseNumber < widget.workout.exerciseList.length
                  ? "Next"
                  : "Done",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }""";

  final actionRowReplacement = """  Widget _buildGradientButton({
    required String text,
    required VoidCallback? onPressed,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: onPressed != null
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: onPressed == null ? Colors.white.withOpacity(0.05) : null,
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: onPressed != null ? Colors.white : Colors.white38,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActionRow() {
    return Row(
      children: [
        Expanded(
          child: _buildGradientButton(
            text: "Previous",
            onPressed: widget.exerciseNumber > 1
                ? () async {
                    if (widget.isReadOnlyMode) {
                      await _openExercise(widget.exerciseNumber - 1);
                    } else {
                      await _handleBackNavigation();
                    }
                  }
                : null,
            gradientColors: [Colors.grey[800]!, Colors.grey[700]!],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGradientButton(
            text: widget.isReadOnlyMode
                ? (widget.exerciseNumber < widget.workout.exerciseList.length
                    ? "Next"
                    : "Back")
                : widget.exerciseNumber < widget.workout.exerciseList.length
                    ? "Next"
                    : "Done",
            onPressed: () async {
              int totalExercises = widget.workout.exerciseList.length;

              if (widget.isReadOnlyMode) {
                if (widget.exerciseNumber < totalExercises) {
                  await _openExercise(widget.exerciseNumber + 1);
                } else if (mounted) {
                  Navigator.pop(context);
                }
                return;
              }

              if (!await _validateTrackingInputs()) {
                return;
              }

              _markExerciseAsViewed();
              _notifyValidWeightInput();

              if (widget.exerciseNumber < totalExercises) {
                await _saveExerciseRecord();
                await _openExercise(widget.exerciseNumber + 1);
              } else {
                await _saveExerciseRecord();
                Navigator.pop(context);
              }
            },
            gradientColors: widget.isReadOnlyMode
                ? (widget.exerciseNumber < widget.workout.exerciseList.length ? [Colors.orange, Colors.deepOrange] : [Colors.grey[800]!, Colors.grey[700]!])
                : (widget.exerciseNumber < widget.workout.exerciseList.length ? [Colors.orange, Colors.deepOrange] : [Colors.green, Colors.green[700]!]),
          ),
        ),
      ],
    );
  }""";

  // Also replace mobile reps/sets text fields just in case!
  final mobileRepsTarget = """                                              Expanded(
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
                                              ),""";

  final mobileRepsReplacement = """                                              Expanded(
                                                child: _buildPremiumTextField(
                                                  controller: repsController,
                                                  labelText: 'Reps',
                                                  helperText: 'Whole numbers only',
                                                ),
                                              ),""";

  final mobileSetsTarget = """                                              Expanded(
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
                                              ),""";

  final mobileSetsReplacement = """                                              Expanded(
                                                child: _buildPremiumTextField(
                                                  controller: setsController,
                                                  labelText: 'Sets',
                                                  helperText: 'Whole numbers only',
                                                ),
                                              ),""";

  String normalize(String s) {
    return s.replaceAll(RegExp(r'[ \t]+\n'), '\n');
  }

  content = normalize(content);
  
  if (content.contains(normalize(actionRowTarget))) {
    content = content.replaceAll(normalize(actionRowTarget), actionRowReplacement);
    print("Action row replaced");
  } else {
    print("Action row not found");
  }

  if (content.contains(normalize(mobileRepsTarget))) {
    content = content.replaceAll(normalize(mobileRepsTarget), mobileRepsReplacement);
    print("Mobile reps replaced");
  } else {
    print("Mobile reps not found");
  }

  if (content.contains(normalize(mobileSetsTarget))) {
    content = content.replaceAll(normalize(mobileSetsTarget), mobileSetsReplacement);
    print("Mobile sets replaced");
  } else {
    print("Mobile sets not found");
  }

  file.writeAsStringSync(content);
}
