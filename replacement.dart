  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String timeStr;
    if (_bookedSlots.isNotEmpty) {
      timeStr = _bookedSlots
          .map((s) => "${s.startTime} - ")
          .join(', ');
    } else {
      timeStr = widget.ticket.period.split('|').first;
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const AppText(
          text: "Booking Details",
          textStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        ),
        titleSpacing: 0,
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green gradient header with status badge glow
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDarkGreen,
                    Color(0xFF0FA968),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + 60,
                24,
                24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: "Booking #CB${IdUtil.formatDisplayId(widget.ticket.displayId)}",
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.ticket.isPaid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.ticket.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800)).withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AppText(
                      text: widget.ticket.isPaid ? "Confirmed" : "Pending",
                      textStyle: TextStyle(
                        color: widget.ticket.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const _SectionLabel(title: "BOOKING DETAILS"),
                  const SizedBox(height: 12),

                  _SectionCard(
                    child: Column(
                      children: [
                        _DetailRow(
                          label: "Court",
                          value: widget.ticket.venueName,
                          iconData: Icons.sports_tennis_rounded,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Sport",
                          value: widget.ticket.sportName.toUpperCase(),
                          iconData: Icons.sports_volleyball,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Date",
                          value: DateFormat('EEEE, MMM d, yyyy').format(widget.ticket.date),
                          iconData: Icons.calendar_today_rounded,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Time",
                          value: timeStr.replaceAll('', ''),
                          iconData: Icons.access_time_rounded,
                        ),
                        const _RowDivider(),
                        _DetailRow(
                          label: "Booking ID",
                          value: "CB${IdUtil.formatDisplayId(widget.ticket.displayId)}".replaceAll('', ''),
                          iconData: Icons.tag_rounded,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel(title: "PAYMENT SUMMARY"),
                  const SizedBox(height: 12),

                  _SectionCard(
                    child: Column(
                      children: [
                        _PaymentRow(
                          label: "Total Amount",
                          value: "?${widget.ticket.price.toStringAsFixed(0)}".replaceAll('', ''),
                        ),
                        const _RowDivider(),
                        _PaymentRow(
                          label: "Payment Status",
                          value: widget.ticket.isPaid ? "Paid" : "Pending",
                          valueColor: widget.ticket.isPaid ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel(title: "ACCESS CODE"),
                  const SizedBox(height: 12),
                  
                  _SectionCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: theme.dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _QrCodePainter(
                                data: QrCrypto.encryptQrData(
                                    "${widget.ticket.bookingId} | Ground: ${widget.ticket.venueName} | Owner: ${widget.ticket.ownerId} | Ground ID: ${widget.ticket.groundId}"),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppText(
                              text: "Scan at entrance",
                              textStyle: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const _SectionLabel(title: "LOCATION"),
                  const SizedBox(height: 12),
                  SlotSelectionWidgets.buildMapSection(
                    context,
                    latitude: widget.ticket.latitude,
                    longitude: widget.ticket.longitude,
                    address: widget.ticket.location,
                  ),

                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _generateAndDownload,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, color: Colors.white),
            label: Text(
              _isSaving ? "Generating PDF..." : "Download Ticket",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDarkGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.share_outlined,
                color: AppColors.primaryDarkGreen),
            label: const Text("Share with Friends",
                style: TextStyle(
                    color: AppColors.primaryDarkGreen,
                    fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryDarkGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText(
          text: title,
          textStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? iconData;

  const _DetailRow({
    required this.label,
    required this.value,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (iconData != null) ...[
            Icon(
              iconData,
              size: 16,
              color: AppColors.primaryDarkGreen,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: AppText(
              text: label,
              textStyle: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: AppText(
                    text: value,
                    align: TextAlign.right,
                    textStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PaymentRow(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            text: label,
            textStyle: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          AppText(
            text: value,
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Theme.of(context).dividerColor,
      height: 1,
      thickness: 1,
    );
  }
}

class _QrCodePainter extends StatelessWidget {
  final String data;
  const _QrCodePainter({required this.data});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: 120.0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    );
  }
}
