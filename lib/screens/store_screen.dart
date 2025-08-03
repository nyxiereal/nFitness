import 'package:flutter/material.dart';
import '../services/efitness_service.dart';

class StoreScreen extends StatefulWidget {
  final Map<String, dynamic> club;
  const StoreScreen({required this.club, super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final EfitnessService _service = EfitnessService();
  bool _loading = true;
  List<Map<String, dynamic>> _definitions = [];

  @override
  void initState() {
    super.initState();
    _loadDefinitions();
  }

  Future<void> _loadDefinitions() async {
    setState(() => _loading = true);
    final clubId = widget.club['clubId'];
    final defs = await _service.getMembershipDefinitions(clubId);
    setState(() {
      _definitions = defs;
      _loading = false;
    });
  }

  List<String> _parseFeatures(String? desc) {
    if (desc == null || desc.isEmpty) return [];
    return desc
        .split('||')
        .map((f) => f.trimRight())
        .where((f) => f.isNotEmpty)
        .map((f) {
          if (f.isEmpty) return '';
          final trimmed = f.trimLeft();
          if (trimmed.isEmpty) return '';
          return trimmed[0].toUpperCase() + trimmed.substring(1);
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: _loadDefinitions,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _definitions.isEmpty
            ? const Center(child: Text('No products found.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _definitions.length,
                itemBuilder: (context, index) {
                  final def = _definitions[index];
                  final features = _parseFeatures(def['internetDescription']);
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            def['internetName'] ?? def['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (features.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: features
                                  .map(
                                    (f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        "- $f",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                '${def['installmentPrice']?.toStringAsFixed(2) ?? '0.00'} zł',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                def['periodTime'] != null &&
                                        def['periodType'] == 2
                                    ? '${def['periodTime']} month(s)'
                                    : '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
