import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _modelPathPreferenceKey = 'local_llm_model_path';
const String _defaultModelFileName = 'SmolLM-135M-Instruct.Q2_K.gguf';
const String _defaultBundledModelAssetPath = 'models/$_defaultModelFileName';

enum ModelPathSource {
  remoteHostedModel,
  savedPreference,
  bundledDefaultModel,
  projectModelsDirectory,
  missing,
}

class ModelLocationState {
  const ModelLocationState({
    required this.exists,
    required this.source,
    this.path,
    this.suggestedPath,
  });

  final bool exists;
  final ModelPathSource source;
  final String? path;
  final String? suggestedPath;
}

class ModelStorageService {
  Future<ModelLocationState> pickModelFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['gguf'],
      allowMultiple: false,
    );

    final selectedFile = result?.files.single;
    final selectedPath = selectedFile?.path?.trim();
    if (selectedPath == null || selectedPath.isEmpty) {
      return getModelLocation();
    }

    final storedPath = await _storePickedModel(
      selectedPath: selectedPath,
      fileName: selectedFile?.name,
    );
    await saveModelPath(storedPath);
    return getModelLocation();
  }

  Future<void> saveModelPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelPathPreferenceKey, path);
  }

  Future<void> clearModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modelPathPreferenceKey);
  }

  Future<String?> getSavedModelPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_modelPathPreferenceKey)?.trim();
    return savedPath == null || savedPath.isEmpty ? null : savedPath;
  }

  Future<ModelLocationState> getModelLocation() async {
    final savedPath = await getSavedModelPath();
    final suggestedPath = await getSuggestedModelPath();
    final savedFile = _fileFromPath(savedPath);
    if (savedFile != null && await savedFile.exists()) {
      return ModelLocationState(
        exists: true,
        source: ModelPathSource.savedPreference,
        path: savedFile.path,
        suggestedPath: suggestedPath,
      );
    }

    final hydratedSuggestedPath = await _ensureBundledModelAvailable(
      suggestedPath,
    );
    final suggestedFile = _fileFromPath(hydratedSuggestedPath ?? suggestedPath);
    if (suggestedFile != null && await suggestedFile.exists()) {
      return ModelLocationState(
        exists: true,
        source: hydratedSuggestedPath != null
            ? ModelPathSource.bundledDefaultModel
            : ModelPathSource.projectModelsDirectory,
        path: suggestedFile.path,
        suggestedPath: suggestedFile.path,
      );
    }

    return ModelLocationState(
      exists: false,
      source: ModelPathSource.missing,
      suggestedPath: suggestedPath,
    );
  }

  Future<String?> getSuggestedModelPath() async {
    if (kIsWeb) {
      return null;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final appDocumentsDirectory = await getApplicationDocumentsDirectory();
      return File(
        '${appDocumentsDirectory.path}${Platform.pathSeparator}models'
        '${Platform.pathSeparator}$_defaultModelFileName',
      ).path;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return File(
        '${Directory.current.path}${Platform.pathSeparator}models'
        '${Platform.pathSeparator}$_defaultModelFileName',
      ).path;
    }

    return null;
  }

  File? _fileFromPath(String? path) {
    final normalizedPath = path?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return null;
    }
    return File(normalizedPath);
  }

  bool get _supportsBundledModelProvisioning =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<String?> _ensureBundledModelAvailable(String? suggestedPath) async {
    if (!_supportsBundledModelProvisioning || suggestedPath == null) {
      return null;
    }

    final targetFile = File(suggestedPath);
    if (await targetFile.exists()) {
      return targetFile.path;
    }

    final bundledModel = await _loadBundledModelBytes();
    if (bundledModel == null) {
      return null;
    }

    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(
      bundledModel.buffer.asUint8List(
        bundledModel.offsetInBytes,
        bundledModel.lengthInBytes,
      ),
      flush: true,
    );
    return targetFile.path;
  }

  Future<ByteData?> _loadBundledModelBytes() async {
    try {
      return await rootBundle.load(_defaultBundledModelAssetPath);
    } catch (_) {
      return null;
    }
  }

  Future<String> _storePickedModel({
    required String selectedPath,
    String? fileName,
  }) async {
    if (kIsWeb) {
      return selectedPath;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      return selectedPath;
    }

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final modelsDirectory = Directory(
      p.join(documentsDirectory.path, 'models'),
    );
    await modelsDirectory.create(recursive: true);

    final rawName = (fileName ?? p.basename(selectedPath)).trim();
    final normalizedName = rawName.isEmpty ? _defaultModelFileName : rawName;
    final targetPath = p.join(modelsDirectory.path, normalizedName);

    if (p.equals(selectedPath, targetPath)) {
      return targetPath;
    }

    final sourceFile = File(selectedPath);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    await sourceFile.copy(targetPath);
    return targetFile.path;
  }
}
