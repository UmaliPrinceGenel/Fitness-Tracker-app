import re

file_path = r"c:\Users\Kean\OneDrive\Desktop\rockies-fitness-tracker\Fitness-Tracker-app\lib\screens\exercise_detail_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace divider color in Result Details
content = content.replace("color: Colors.white38,", "color: Colors.white10,")

# Replace _buildBottomActionRow
action_row_target = """  Widget _buildBottomActionRow() {
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
  }"""

action_row_replacement = """  Widget _buildGradientButton({
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
            gradientColors: widget.exerciseNumber < widget.workout.exerciseList.length || widget.isReadOnlyMode
                ? [Colors.orange, Colors.deepOrange]
                : [Colors.green, Colors.green[700]!], // Green for 'Done'
          ),
        ),
      ],
    );
  }"""

def normalize(s):
    return re.sub(r'[ \t]+\n', '\n', s)

content_norm = normalize(content)
target_norm = normalize(action_row_target)

if target_norm in content_norm:
    content_norm = content_norm.replace(target_norm, action_row_replacement)
    print("Replaced action row successfully!")
else:
    print("Could not find action row target")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content_norm)
