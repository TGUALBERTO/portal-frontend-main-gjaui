import 'package:gjamobile/src/imports/core_imports.dart';

/// Name + description fields for a group. Rendered inside the screen's [Form].
class GroupFormSection extends StatelessWidget {
  const GroupFormSection({
    super.key,
    required this.nameController,
    required this.descriptionController,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          label: 'Nome',
          hint: 'Nome do grupo',
          controller: nameController,
          textInputAction: TextInputAction.next,
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return 'Informe um nome';
            if (value.length > 120) return 'Máximo de 120 caracteres';
            return null;
          },
        ),
        SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'Descrição',
          hint: 'Descrição (opcional)',
          controller: descriptionController,
          maxLines: 3,
          minLines: 2,
          validator: (v) {
            if ((v?.trim().length ?? 0) > 500) {
              return 'Máximo de 500 caracteres';
            }
            return null;
          },
        ),
      ],
    );
  }
}
