import 'package:flutter/material.dart';
import 'package:gjamobile/src/features/access/domain/enums/empresas.dart';
import 'package:gjamobile/src/features/inbound/shared/domain/enums/sap_backend.dart';

class EmpresaSapField extends StatelessWidget {
  const EmpresaSapField({
    super.key,
    required this.empresa,
    required this.onChanged,
  });

  final Empresa? empresa;
  final ValueChanged<Empresa?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Empresa>(
      key: ValueKey(empresa),
      initialValue: empresa,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Empresa'),
      hint: const Text('Selecione a empresa'),
      items: [
        for (final item in Empresa.values)
          if (sapBackendForEmpresa(item) != null)
            DropdownMenuItem(
              value: item,
              child: Text(item.razaoSocial, overflow: TextOverflow.ellipsis),
            ),
      ],
      onChanged: onChanged,
    );
  }
}
