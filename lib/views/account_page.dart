import 'package:flutter/material.dart';
import '../core/theme/custom_colors.dart';
import '../core/widgets/page_header.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    // Couleur d'accentuation principale (orange de votre thème ou fallback)
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: colors.mainBackgroundColor,
      body: Column(
        children: [
          const PageHeader(title: 'Mon Compte'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            primaryColor, // Utilise la couleur d'accentuation orange
                        child: const Text(
                          'YO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Moi',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@moi · Toulouse',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.more_horiz, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Cartes de statistiques (Événements, À venir, Organisés)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          count: '6',
                          label: 'Événements',
                          highlightColor: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          count: '3',
                          label: 'À venir',
                          highlightColor: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          count: '2',
                          label: 'Organisés',
                          highlightColor: primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Sélecteur Mode sombre
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1E1E1E,
                      ), // Arrière-plan de carte sombre
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.nightlight_round_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Mode sombre',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: isDarkMode,
                          onChanged: (val) {
                            setState(() {
                              isDarkMode = val;
                            });
                          },
                          activeThumbColor: Colors.white,
                          activeTrackColor: primaryColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Menu d'options
                  _buildMenuItem(title: 'Notifications', onTap: () {}),
                  _buildMenuItem(title: 'Confidentialité', onTap: () {}),
                  _buildMenuItem(title: "Demandes d'amis (2)", onTap: () {}),
                  _buildMenuItem(title: 'Aide', onTap: () {}),
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    title: 'Se déconnecter',
                    textColor: const Color(0xFFE53935),
                    showChevron: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String count,
    required String label,
    required Color highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: TextStyle(
              color: highlightColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    bool showChevron = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
