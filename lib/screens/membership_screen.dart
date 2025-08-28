import 'package:flutter/material.dart';
import '../services/efitness_service.dart';

class MembershipScreen extends StatefulWidget {
  final Map<String, dynamic> club;

  const MembershipScreen({required this.club, super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final EfitnessService _service = EfitnessService();
  Map<String, dynamic>? _membershipInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembershipInfo();
  }

  Future<void> _loadMembershipInfo() async {
    setState(() => _isLoading = true);
    final clubId = widget.club['clubId'];
    final membership = await _service.getMembershipInfo(clubId);
    setState(() {
      _membershipInfo = membership;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadMembershipInfo,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _membershipInfo == null
            ? const Center(child: Text('Unable to load membership information'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Membership Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            'Name',
                            _membershipInfo!['name'] ?? 'N/A',
                          ),
                          _buildInfoRow(
                            'Status',
                            _membershipInfo!['isValid'] == true
                                ? 'Active'
                                : 'Inactive',
                          ),
                          _buildInfoRow(
                            'From',
                            _formatDate(_membershipInfo!['from']),
                          ),
                          _buildInfoRow(
                            'To',
                            _formatDate(_membershipInfo!['to']),
                          ),
                          _buildInfoRow(
                            'Signed',
                            _formatDate(_membershipInfo!['signed']),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Membership Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  (_membershipInfo!['isValid'] == true
                                          ? Colors.green
                                          : Colors.red)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _membershipInfo!['isValid'] == true
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _membershipInfo!['isValid'] == true
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: _membershipInfo!['isValid'] == true
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _membershipInfo!['isValid'] == true
                                      ? 'Active Membership'
                                      : 'Inactive Membership',
                                  style: TextStyle(
                                    color: _membershipInfo!['isValid'] == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
