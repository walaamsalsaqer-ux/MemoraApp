import 'package:flutter/material.dart';

const kPrimary = Color(0xFF5B2E91);

class PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.title, required
  this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius:
          BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
        child: Text(title, style: const TextStyle(fontSize: 16,
            fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 15,
          fontWeight: FontWeight.w800)),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  const SoftCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, spreadRadius: 0, offset:
          Offset(0, 4), color: Color(0x12000000)),
        ],
      ),
      child: child,
    );
  }
}

class PillSwitch extends StatelessWidget {
  final String left;
  final String right;
  final bool isRightSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const PillSwitch({
    super.key,
    required this.left,
    required this.right,
    required this.isRightSelected,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _chip(
              title: left,
              selected: !isRightSelected,
              onTap: onLeft,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _chip(
              title: right,
              selected: isRightSelected,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({required String title, required bool selected,
    required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}