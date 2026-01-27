# VNBS Runtime (Berry Runtime)

Visual Novel Runtime Engine for games created with Choccy IDE.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  vnbs_runtime:
    git:
      url: https://github.com/NGLSG/Berry_Runtime.git
      ref: master
```

## Usage

```dart
import 'package:vnbs_runtime/vnbs_runtime.dart';

// Load story bundle
final bundle = VNStoryBundle.fromJson(storyData);

// Create engine
final engine = VNEngine(bundle);

// Start the story
engine.start();
```

## License

Proprietary - See LICENSE file for details.
