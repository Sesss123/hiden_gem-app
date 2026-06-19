import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/oracle_ui_system.dart';
import '../../data/models/broadcast_message.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/datasources/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuideBroadcastScreen extends StatefulWidget {
  final String sessionId;
  const GuideBroadcastScreen({super.key, required this.sessionId});

  @override
  State<GuideBroadcastScreen> createState() => _GuideBroadcastScreenState();
}

class _GuideBroadcastScreenState extends State<GuideBroadcastScreen> {
  final _messageController = TextEditingController();
  final _broadcastRepo = BroadcastRepository();
  bool _isSending = false;
  BroadcastType _selectedType = BroadcastType.general;
  BroadcastPriority _selectedPriority = BroadcastPriority.normal;

  Future<void> _sendBroadcast() async {
    if (_messageController.text.isEmpty) return;

    setState(() => _isSending = true);
    final uid = AuthService().currentUser?.uid ?? "unknown";
    
    final message = BroadcastMessage(
      messageId: const Uuid().v4(),
      sessionId: widget.sessionId,
      guideId: uid,
      type: _selectedType,
      title: _selectedType.name.toUpperCase(),
      body: _messageController.text,
      priority: _selectedPriority,
      createdAt: DateTime.now(),
      requiresAck: _selectedPriority == BroadcastPriority.critical,
    );

    await _broadcastRepo.sendBroadcast(message);
    
    _messageController.clear();
    setState(() => _isSending = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BROADCAST SENT SUCCESSFULLY")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OracleUI.auraBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: OracleUI.neonText("BROADCAST CENTER", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMessageInput(),
                  const SizedBox(height: 32),
                  OracleUI.neonText("ACTIVE BROADCASTS", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildBroadcastStream(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return OracleUI.glassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("CREATE BROADCAST", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            maxLines: 3,
            style: GoogleFonts.inter(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter your message to travelers...",
              hintStyle: GoogleFonts.inter(color: Colors.white24),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white10)),
              filled: true,
              fillColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 24),
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildPrioritySelector(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSending ? null : _sendBroadcast,
              child: _isSending 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : Text("SEND TO ALL TRAVELERS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BroadcastType.values.map((type) {
        final isSelected = _selectedType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedType = type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white10),
            ),
            child: Text(
              type.name.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        Text("PRIORITY: ", style: GoogleFonts.outfit(fontSize: 10, color: Colors.white54)),
        const SizedBox(width: 8),
        ...BroadcastPriority.values.map((p) {
          final isSelected = _selectedPriority == p;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 10)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedPriority = p),
              selectedColor: _getPriorityColor(p).withOpacity(0.3),
              labelStyle: TextStyle(color: isSelected ? _getPriorityColor(p) : Colors.white54),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: isSelected ? _getPriorityColor(p) : Colors.white10),
            ),
          );
        }),
      ],
    );
  }

  Color _getPriorityColor(BroadcastPriority p) {
    switch (p) {
      case BroadcastPriority.critical: return Colors.redAccent;
      case BroadcastPriority.high: return Colors.orangeAccent;
      case BroadcastPriority.normal: return Colors.blueAccent;
      case BroadcastPriority.low: return Colors.grey;
    }
  }

  Widget _buildBroadcastStream() {
    return StreamBuilder<List<BroadcastMessage>>(
      stream: _broadcastRepo.getActiveBroadcasts(widget.sessionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!;
        
        if (messages.isEmpty) {
          return Center(
            child: Text("No active broadcasts.", style: GoogleFonts.inter(color: Colors.white24)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: OracleUI.glassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          msg.type.name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(msg.priority),
                          ),
                        ),
                        Text(
                          "${msg.acknowledgedBy.length} Acks",
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(msg.body, style: GoogleFonts.inter(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}",
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.white24),
                        ),
                        TextButton(
                          onPressed: () => _broadcastRepo.deactivateBroadcast(widget.sessionId, msg.messageId),
                          child: Text("EXPIRE", style: GoogleFonts.outfit(fontSize: 10, color: Colors.redAccent.withOpacity(0.5))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 100).ms);
          },
        );
      },
    );
  }
}
