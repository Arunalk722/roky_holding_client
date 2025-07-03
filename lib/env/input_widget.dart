import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roky_holding/env/text_input_object.dart';
import 'package:pattern_formatter/pattern_formatter.dart';

Widget buildPwdTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    bool visible,
    int maxLength,
    ) {  return _BuildPwdTextField(    controller: controller,    label: label,    hint: hint,    icon: icon,    visible: visible,    maxLength: maxLength,  );}

class _BuildPwdTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool visible;
  final int maxLength;

  const _BuildPwdTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.visible,
    required this.maxLength,
  });

  @override
  _BuildPwdTextFieldState createState() => _BuildPwdTextFieldState();
}

class _BuildPwdTextFieldState extends State<_BuildPwdTextField> {
  bool _obscureText = true; // Password visibility toggle

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Visibility(
        visible: widget.visible,
        child: TextFormField(
          maxLength: widget.maxLength,
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon),

            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),

              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });

              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter ${widget.label}';
            }
            return null;
          },
        ),
      ),
    );
  }
}



Widget buildTextField(TextEditingController controller, String label,String hint, IconData icon, bool visible, int MaxLenth) {
  return SizedBox(
      child: Visibility(
          visible: visible,
          child: TextFormField(
            maxLength: MaxLenth,
            controller: controller,
            decoration: InputTextDecoration.inputDecoration(
              lable_Text: label,
              hint_Text: hint,
              icons: icon,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          )
      )
  );
}

Widget buildTextFieldReadOnly(TextEditingController controller, String label, String hint, IconData icon, bool visible, int MaxLenth) {
  return SizedBox(
      child: Visibility(
          visible: visible,
          child: TextFormField(
            readOnly: true,
            maxLength: MaxLenth,
            controller: controller,
            decoration: InputTextDecoration.inputDecoration(
              lable_Text: label,
              hint_Text: hint,
              icons: icon,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          )));
}

Widget buildNumberField(TextEditingController controller,String label,String hint,dynamic  icon,bool vis,int maxLength) {
  return SizedBox(
    child: Visibility(
      visible: vis,
      child: TextFormField(
        maxLength: maxLength,
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon is IconData
              ? Icon(icon) // If IconData, wrap with Icon()
              : icon,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          ThousandsFormatter(allowFraction: true)
        ],

      ),
    ),
  );
}

Widget buildReadOnlyTotalCostField(TextEditingController controller,String label, String hint, IconData icon, int MaxLenth) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextFormField(
        maxLength: MaxLenth,
        decoration: InputTextDecoration.inputDecoration(
          lable_Text: label,
          hint_Text: hint,
          icons: icon,
        ),
        readOnly: true,
        controller: TextEditingController(text: controller.text),
      ),
    ),
  );
}

class AutoSuggestionField extends StatefulWidget {
  final List<String> suggestions;
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onChanged; // Optional callback

  const AutoSuggestionField({
    super.key,
    required this.suggestions,
    required this.controller,
    required this.label,
    this.onChanged,
  });

  @override
  _AutoSuggestionFieldState createState() => _AutoSuggestionFieldState();
}

class _AutoSuggestionFieldState extends State<AutoSuggestionField> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController(text: widget.controller.text);
  }

  @override
  void dispose() {
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue val) {
            if (val.text.isEmpty) {
              return const Iterable<
                  String>.empty(); // Return an empty iterable when text is empty
            }
            return widget.suggestions.where((option) =>
                option.toLowerCase().contains(val.text.toLowerCase()));
          },
          onSelected: (String value) {
            setState(() {
              _internalController.text = value;
              widget.controller.text = value; // Sync with external controller
            });
            if (widget.onChanged != null) {
              widget.onChanged!(value); // Notify parent widget if needed
            }
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: _internalController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: widget.label,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                widget.controller.text =
                    value; // Keep external controller updated
                if (widget.onChanged != null) {
                  widget.onChanged!(value);
                }
              },
              validator: (value) => value == null || value.isEmpty
                  ? 'Please select a value'
                  : null,
            );
          },
        ),
      ),
    );
  }
}

/*
AutoSuggestionField(
  label: 'Enter Location',
  suggestions: _locationSuggestions,
  controller: _locationController,
  onChanged: (value) {
    PD.pd(text: "Typed Location: $value"); // Debug log
  },
),

*/

class CustomDropdown extends StatefulWidget {
  final String label;
  final List<String> suggestions;
  final IconData icon;
  final TextEditingController controller;
  final ValueChanged<String?>? onChanged; // Optional callback

  const CustomDropdown({
    super.key,
    required this.label,
    required this.suggestions,
    required this.icon,
    required this.controller,
    this.onChanged,
  });

  @override
  _CustomDropdownState createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(widget.icon),
        ),
        value: widget.suggestions.contains(widget.controller.text) ? widget.controller.text : null,
        items: widget.suggestions.map((value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            widget.controller.text = value ?? ''; // ✅ Update controller
          });
          if (widget.onChanged != null) {
            widget.onChanged!(value); // Notify parent widget
          }
        },
        validator: (value) => value == null || value.isEmpty ? 'Please select a value' : null,
      ),
    );
  }
}


/*
 CustomDropdown(
 label: 'Select Cost Type',
  suggestions: _dropdownCostType,
   icon: Icons.category_sharp,
   controller: _dropdown1Controller,
   onChanged: (value) {
  _selectedValueCostType=value;
 },
),
*/

Widget buildDetailRow(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the top
      children: [
        SizedBox(
          width: 120, // Fixed width for labels for better alignment
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Expanded( // Use Expanded to take up remaining space
          child: Text(
            value != null ? value.toString() : 'Not available',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    ),
  );
}


//date time picker
class DatePickerWidget extends StatefulWidget {
  final String label;
  final Function(String) onDateSelected;
  final String? initialDate; // Add this to accept initial date

  const DatePickerWidget({
    required this.label,
    required this.onDateSelected,
    this.initialDate, // Add this parameter
  });

  @override
  DatePickerWidgetState createState() => DatePickerWidgetState();
}
class DatePickerWidgetState extends State<DatePickerWidget> {
  late String _selectedDate;
  @override
  void initState() {
    super.initState();
    // Initialize with the provided initial date or default text
    _selectedDate = widget.initialDate ?? 'No date selected';
  }
  @override
  void didUpdateWidget(covariant DatePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the displayed date when the parent provides a new initialDate
    if (widget.initialDate != oldWidget.initialDate) {
      setState(() {
        _selectedDate = widget.initialDate ?? 'No date selected';
      });
    }
  }
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != 'No date selected'
          ? DateTime.parse(_selectedDate)
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      final formattedDate = "${picked.toLocal()}".split(' ')[0];
      setState(() {
        _selectedDate = formattedDate;
      });
      widget.onDateSelected(formattedDate);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedDate, style: const TextStyle(fontSize: 16)),
                const Icon(Icons.calendar_today, color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



Widget buildNumberWithReadOption(
    TextEditingController controller,
    String label,
    String hint,
    dynamic icon, // Can be IconData or Widget
    bool isReadOnly,
    int maxLength
    ) {
  return SizedBox(
    child: TextFormField(
      readOnly: isReadOnly,
      maxLength: maxLength,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon is IconData
            ? Icon(icon) // If IconData, wrap with Icon()
            : icon,      // If Widget (like LKRIcon), use directly
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        ThousandsFormatter(allowFraction: true)
      ],
    ),
  );
}
