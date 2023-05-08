import 'package:flutter/material.dart';

Widget defaultFormField({
  required TextEditingController controller,
  required TextInputType type,
  required String label,
  required Function validate,
  required IconData prefix,
  String hint = 'Search',
  bool isClickable = true,
  Function? onSubmit,
  Function? onChange,
  Function? onTap,
}) =>
    TextFormField(
      controller: controller,
      keyboardType: type,
      onTap: () {
        onTap!();
      },
      onFieldSubmitted: (value) {
        onSubmit!(value);
      },
      onChanged: (value) {
        onChange!(value);
      },
      validator: (value) {
        return validate(value);
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          prefix,
        ),
        border: const OutlineInputBorder(),
      ),
    );