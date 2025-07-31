import 'package:flutter/material.dart';

class MultiSelectDropDown extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final void Function(List<String>) onChanged;
  final String label;
  final List<String> initialSelectedItems; // Added initial selection

  const MultiSelectDropDown({
    super.key,
    required this.items,
    required this.onChanged,
    required this.label,
    this.initialSelectedItems = const [], // Default to empty list
  });

  @override
  _MultiSelectDropDownState createState() => _MultiSelectDropDownState();
}

class _MultiSelectDropDownState extends State<MultiSelectDropDown> {
  List<String> _selectedItems = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected items
    _selectedItems.addAll(widget.initialSelectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpen = !_isOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedItems.isEmpty
                      ? widget.label
                      : _selectedItems.join(', '),
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_isOpen)
          Card(
            elevation: 4,
            margin: const EdgeInsets.only(top: 4),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.items.map((item) {
                  final itemName = item['project_name'] as String;
                  final isSelected = _selectedItems.contains(itemName);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedItems.remove(itemName);
                        } else {
                          _selectedItems.add(itemName);
                        }
                        widget.onChanged(_selectedItems);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedItems.add(itemName);
                                } else {
                                  _selectedItems.remove(itemName);
                                }
                                widget.onChanged(_selectedItems);
                              });
                            },
                          ),
                          Text(itemName),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: MultiSelectDropDown(
            label: 'Select Projects',
            items: const [
              {'project_name': 'Project A'},
              {'project_name': 'Project B'},
              {'project_name': 'Project C'},
              {'project_name': 'Project D'},
            ],
            initialSelectedItems: const ['Project A', 'Project C'], // Example initial selection
            onChanged: (selectedItems) {
              print('Selected Projects: $selectedItems');
            },
          ),
        ),
      ),
    ),
  ));
}
