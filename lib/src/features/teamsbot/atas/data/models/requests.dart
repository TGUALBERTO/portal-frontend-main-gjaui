/// Corpo de `POST /api/atas/gerar`.
class GerarAtaRequest {
  final String userId;
  final String meetingId;
  final String transcriptId;
  final bool? force;

  const GerarAtaRequest({
    required this.userId,
    required this.meetingId,
    required this.transcriptId,
    this.force,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'meetingId': meetingId,
        'transcriptId': transcriptId,
        if (force != null) 'force': force,
      };
}
