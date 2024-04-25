import 'dart:async';
import 'dart:collection';

class FutureQueue {
  final Duration timeout;
  final _controller = StreamController<_QueuedFunction>();
  final Queue<_QueuedFunction> _queue = Queue<_QueuedFunction>();
  bool _isProcessing = false;

  FutureQueue({this.timeout = Duration.zero}) {
    _controller.stream.listen(
      (task) {
        _queue.add(task);
        if (!_isProcessing) {
          _processQueue();
        }
      },
    );
  }

  Future<dynamic> addToQueue(Future<void> Function() function) {
    final completer = Completer<dynamic>();
    _controller.add(
      _QueuedFunction(
        function,
        completer,
      ),
    );
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    final queuedFunction = _queue.removeFirst();
    final function = queuedFunction.function;
    await Future.delayed(timeout);

    try {
      final res = await function();
      queuedFunction.completer.complete(res);
    } catch (err) {
      queuedFunction.completer.completeError(err);
    }

    _isProcessing = false;

    if (_queue.isNotEmpty) {
      _processQueue();
    }
  }

  void dispose() {
    _controller.close();
  }
}

class _QueuedFunction {
  final Function function;
  final Completer<dynamic> completer;

  _QueuedFunction(this.function, this.completer);
}
