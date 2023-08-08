import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ordered_list/list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ordered List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Ordered List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _done = false;
  final List<CustomListItem> _items = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then(
      (sp) {
        var keys = sp.getKeys();
        for (var uuid in keys) {
          _items.add(CustomListItem.fromStorage(uuid, sp.getStringList(uuid)!));
        }

        setState(() {
          _done = true;
        });
      },
    );
  }

  void _removeElementConfirmation({CustomListItem? element}) {
    showDialog(
        context: context,
        builder: ((context) {
          return AlertDialog(
            scrollable: true,
            title: const Text("Are you sure?"),
            content: const Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Text("The action is irreversible."),
                )),
            actions: [
              TextButton(
                  onPressed: (() => Navigator.pop(context)),
                  child: const Text("Cancel")),
              ElevatedButton(
                onPressed: (() {
                  if (element != null) {
                    _removeElement(element);
                  } else {
                    _clearAll();
                  }
                  Navigator.pop(context);
                }),
                child: const Text("Delete"),
              ),
            ],
          );
        }));
  }

  void _editElement(CustomListItem element) {
    showDialog(
      context: context,
      builder: ((context) {
        var textController = TextEditingController(text: element.text);
        var numberController =
            TextEditingController(text: element.number.toString());
        var formKey = GlobalKey<FormState>();
        return AlertDialog(
          scrollable: true,
          title: const Text("Add element"),
          content: Padding(
            padding: const EdgeInsets.all(8),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(hintText: "Insert text here."),
                    controller: textController,
                    keyboardType: TextInputType.text,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.singleLineFormatter
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return "Text field should not be empty";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(hintText: "Insert number here."),
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.singleLineFormatter,
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return "Number field should not be empty";
                      }
                      if (int.tryParse(value) == null) {
                        return "This should be a number";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: (() => Navigator.pop(context)),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: (() {
                if (formKey.currentState!.validate()) {
                  element.updateValues(
                      textController.text, int.parse(numberController.text));
                  element.asyncSaveToStorage();
                  Navigator.pop(context);
                  _sortAscending();
                }
              }),
              child: const Text("Update"),
            ),
          ],
        );
      }),
    );
  }

  void _removeElement(CustomListItem element) {
    element.asyncRemoveFromStorage();
    setState(() => _items.remove(element));
  }

  void _asyncClearStorage() async {
    SharedPreferences.getInstance().then(
        (value) => value.getKeys().forEach((element) => value.remove(element)));
  }

  void _clearAll() async {
    _asyncClearStorage();
    setState(() => _items.removeWhere((e) => true));
  }

  void _addElement() {
    showDialog(
      context: context,
      builder: ((context) {
        var textController = TextEditingController();
        var numberController = TextEditingController();
        var formKey = GlobalKey<FormState>();
        return AlertDialog(
          scrollable: true,
          title: const Text("Add element"),
          content: Padding(
            padding: const EdgeInsets.all(8),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(hintText: "Insert text here."),
                    controller: textController,
                    keyboardType: TextInputType.text,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.singleLineFormatter
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return "Text field should not be empty";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(hintText: "Insert number here."),
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.singleLineFormatter,
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value!.trim().isEmpty) {
                        return "Number field should not be empty";
                      }
                      if (int.tryParse(value) == null) {
                        return "This should be a number";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: (() => Navigator.pop(context)),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: (() {
                if (formKey.currentState!.validate()) {
                  var cli = CustomListItem(
                      text: textController.text,
                      number: int.parse(numberController.text),
                      uuid: const Uuid().v1());
                  cli.asyncSaveToStorage();
                  setState(() {
                    _items.add(cli);
                    Navigator.pop(context);
                  });
                }
              }),
              child: const Text("Add"),
            ),
          ],
        );
      }),
    );
  }

  void _sortAscending() {
    _items.sort(((a, b) => a.compareTo(b)));
    setState(() {});
  }

  void _sortDescending() {
    _items.sort(((a, b) => a.compareTo(b) * -1));
    setState(() {});
  }

  Widget _getBody() {
    if (!_done) {
      return const Center(
        child: SizedBox(
          height: 250,
          width: 250,
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text("The list is empty."),
      );
    }
    return Center(
      child: ListView.builder(
        itemBuilder: ((context, index) {
          return SizedBox(
            width: 350,
            height: 100,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.grey,
                          offset: Offset.zero,
                          blurRadius: 4,
                          spreadRadius: 2,
                          blurStyle: BlurStyle.normal)
                    ],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: ListTile(
                      onLongPress: () => _editElement(_items[index]),
                      leading: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _removeElementConfirmation(element: _items[index]),
                      ),
                      title: Text(
                        _items[index].text,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      trailing: Text(
                        "${_items[index].number}",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        itemCount: _items.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: _removeElementConfirmation,
              icon: const Icon(Icons.delete_sweep))
        ],
        title: Text(widget.title),
      ),
      body: _getBody(),
      floatingActionButton: ExpandableFab(distance: 60, children: [
        ActionButton(
          icon: const Icon(Icons.add),
          onPressed: () => _addElement(),
        ),
        ActionButton(
          icon: const Icon(Icons.format_list_numbered_rtl),
          onPressed: () => _sortAscending(),
        ),
        ActionButton(
          icon: ImageIcon(
              Image.asset("assets/list_ordered_descending.png").image),
          onPressed: () => _sortDescending(),
        )
      ]),
    );
  }
}

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.initialOpen,
    required this.distance,
    required this.children,
  });

  final bool? initialOpen;
  final double distance;
  final List<Widget> children;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = widget.initialOpen ?? false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          _buildTapToCloseFab(),
          ..._buildExpandingActionButtons(),
          _buildTapToOpenFab(),
        ],
      ),
    );
  }

  Widget _buildTapToCloseFab() {
    return SizedBox(
      width: 65,
      height: 65,
      child: Center(
        child: Material(
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          child: InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ExpandingActionButton(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() {
    return IgnorePointer(
      ignoring: _open,
      child: AnimatedContainer(
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          _open ? 0.7 : 1.0,
          _open ? 0.7 : 1.0,
          1.0,
        ),
        duration: const Duration(milliseconds: 250),
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        child: AnimatedOpacity(
          opacity: _open ? 0.0 : 1.0,
          curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
          duration: const Duration(milliseconds: 250),
          child: FloatingActionButton(
            onPressed: _toggle,
            child: const Icon(Icons.create),
          ),
        ),
      ),
    );
  }
}

@immutable
class _ExpandingActionButton extends StatelessWidget {
  const _ExpandingActionButton({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final offset = Offset.fromDirection(
          directionInDegrees * (math.pi / 180.0),
          progress.value * maxDistance,
        );
        return Positioned(
          right: 4.0 + offset.dx,
          bottom: 4.0 + offset.dy,
          child: Transform.rotate(
            angle: (1.0 - progress.value) * math.pi / 2,
            child: child!,
          ),
        );
      },
      child: FadeTransition(
        opacity: progress,
        child: child,
      ),
    );
  }
}

@immutable
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    this.onPressed,
    required this.icon,
  });

  final VoidCallback? onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.secondary,
      elevation: 4,
      child: IconButton(
        onPressed: onPressed,
        icon: icon,
        color: theme.colorScheme.onSecondary,
      ),
    );
  }
}
