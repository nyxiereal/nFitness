import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/efitness_service.dart';

class AccountScreen extends StatefulWidget {
  final Map<String, dynamic> club;
  final Map<String, dynamic>? membershipInfo;

  const AccountScreen({
    required this.club,
    required this.membershipInfo,
    super.key,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final EfitnessService _service = EfitnessService();
  List<Map<String, dynamic>> _notifications = [];
  Set<String> _readHashes = {};
  int _unreadCount = 0;
  bool _loading = true;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _creditCard;
  bool _profileLoading = true;
  bool _creditCardLoading = true;
  String? _email;
  int? _gender;
  int? _originalGender;
  bool _woke = true;

  @override
  void initState() {
    super.initState();
    _loadReadHashes().then((_) => _loadNotifications());
    _loadProfile();
    _loadCreditCard();
    _loadWoke();
  }

  Future<void> _loadWoke() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _woke = prefs.getBool('wokeSwitch') ?? true;
    });
  }

  Future<void> _loadProfile() async {
    setState(() => _profileLoading = true);
    final clubId = widget.club['clubId'];
    final profile = await _service.getMemberProfile(clubId);
    final prefs = await SharedPreferences.getInstance();
    int? genderOverride = prefs.getInt('genderOverride');
    String? emailOverride = prefs.getString('emailOverride');
    setState(() {
      _profile = profile;
      _profileLoading = false;
      _email = emailOverride ?? profile?['email'];
      _gender = genderOverride ?? profile?['gender'];
      _originalGender = profile?['gender'];
    });
  }

  Future<void> _loadCreditCard() async {
    setState(() => _creditCardLoading = true);
    final clubId = widget.club['clubId'];
    final cc = await _service.getCreditCardInfo(clubId);
    setState(() {
      _creditCard = cc;
      _creditCardLoading = false;
    });
  }

  Future<void> _loadReadHashes() async {
    final prefs = await SharedPreferences.getInstance();
    final hashes = prefs.getStringList('readNotificationHashes') ?? [];
    _readHashes = hashes.toSet();
  }

  Future<void> _saveReadHashes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('readNotificationHashes', _readHashes.toList());
  }

  String _notificationHash(Map<String, dynamic> notif) {
    final jsonStr = jsonEncode({
      'content': notif['content'],
      'date': notif['date'],
      'title': notif['title'],
    });
    return sha256.convert(utf8.encode(jsonStr)).toString();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final clubId = widget.club['clubId'];
    final notifs = await _service.getNotifications(clubId: clubId);
    final hashes = notifs.map(_notificationHash).toList();
    final unread = <Map<String, dynamic>>[];
    for (var i = 0; i < notifs.length; i++) {
      if (!_readHashes.contains(hashes[i])) {
        unread.add(notifs[i]);
      }
    }
    setState(() {
      _notifications = notifs;
      _unreadCount = unread.length;
      _loading = false;
    });
  }

  Future<void> _showNotificationsModal() async {
    final hashes = _notifications.map(_notificationHash).toSet();
    final newHashes = hashes.difference(_readHashes);
    if (newHashes.isNotEmpty) {
      _readHashes.addAll(newHashes);
      await _saveReadHashes();
      setState(() {
        _unreadCount = 0;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(child: Text('No notifications.'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notif = _notifications[index];
                          final isUnread = !_readHashes.contains(
                            _notificationHash(notif),
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: Card(
                              color: isUnread
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surface,
                              child: ListTile(
                                leading: notif['contentImageUrl'] != null
                                    ? Image.network(
                                        notif['contentImageUrl'],
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.notifications),
                                title: Text(
                                  notif['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notif['content'] ?? '',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm').format(
                                        DateTime.parse(
                                          notif['date'] ??
                                              DateTime.now().toIso8601String(),
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_profileLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_profile == null) {
      return const Text('Failed to load profile.');
    }
    final p = _profile!;
    final genderOptions = [
      {'label': 'Male', 'value': 1},
      {'label': 'Female', 'value': 2},
      {'label': 'Non-Binary', 'value': 3},
      {'label': 'Agender', 'value': 4},
      {'label': 'Business', 'value': 5},
    ];
    final genderLabel = genderOptions.firstWhere(
      (g) => g['value'] == (_woke ? _gender : _originalGender),
      orElse: () => {'label': 'Unknown'},
    )['label'];

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _woke ? Icons.account_circle : Icons.thumb_down_alt,
                  size: 48,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        genderLabel.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildReadOnlyRow('Member ID', p['memberId'], colorScheme),
            _buildReadOnlyRow(
              'Personal ID',
              p['personalIdentityNumber'],
              colorScheme,
            ),
            _buildReadOnlyRow(
              'Birthday',
              p['birthday']?.toString().split('T').first,
              colorScheme,
            ),
            _buildReadOnlyRow('Street', p['street'], colorScheme),
            _buildReadOnlyRow('Flat', p['flatNumber'], colorScheme),
            _buildReadOnlyRow('Postal Code', p['postalCode'], colorScheme),
            _buildReadOnlyRow('City', p['city'], colorScheme),
            _buildReadOnlyRow('Cell Phone', p['cellPhone'], colorScheme),
            _buildReadOnlyRow(
              'Email Verified',
              p['isEmailVerified'] == true ? 'Yes' : 'No',
              colorScheme,
            ),
            _buildReadOnlyRow(
              'Wallet Balance',
              p['walletBalance'],
              colorScheme,
            ),
            _buildReadOnlyRow(
              'Has Credit Card',
              p['hasCreditCard'] == true ? 'Yes' : 'No',
              colorScheme,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) async {
                setState(() => _email = v);
                final prefs = await SharedPreferences.getInstance();
                if (_email != null) {
                  await prefs.setString('emailOverride', _email!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(
    String label,
    dynamic value,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardSection() {
    if (_creditCardLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_creditCard == null) {
      return const Text('No credit card info.');
    }
    final cc = _creditCard!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.credit_card, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cc['valid'] == true
                        ? '**** **** **** ${cc['lastDigits']}'
                        : 'No valid card',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (cc['valid'] == true)
                    Text(
                      'Valid Thru: ${cc['validThruMonth']}/${cc['validThruYear']}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final membershipName = widget.membershipInfo?['name'] ?? 'No Membership';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'Show Notifications',
                onPressed: _showNotificationsModal,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: _showNotificationsModal,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$_unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(Icons.card_membership, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            membershipName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildProfileSection(),
                const SizedBox(height: 16),
                _buildCreditCardSection(),
              ],
            ),
    );
  }
}
