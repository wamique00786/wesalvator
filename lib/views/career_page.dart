// ignore_for_file: use_key_in_widget_constructors, deprecated_member_use
import 'package:flutter/material.dart';

class JobPosting {
  final String title;
  final String location;
  final String type;
  final IconData icon;
  final Color accentColor;

  const JobPosting({
    required this.title,
    required this.location,
    required this.type,
    required this.icon,
    required this.accentColor,
  });
}

class CareerPage extends StatelessWidget {
  final List<JobPosting> jobPostings = const [
    JobPosting(
      title: "Flutter Developer",
      location: "Remote",
      type: "Full-Time",
      icon: Icons.laptop_mac,
      accentColor: Color(0xFF6200EA),
    ),
    JobPosting(
      title: "UI/UX Designer",
      location: "New York",
      type: "Part-Time",
      icon: Icons.palette,
      accentColor: Color(0xFF00BFA5),
    ),
    JobPosting(
      title: "Backend Engineer",
      location: "San Francisco",
      type: "Full-Time",
      icon: Icons.storage,
      accentColor: Color(0xFFFF6D00),
    ),
    JobPosting(
      title: "Product Manager",
      location: "Remote",
      type: "Contract",
      icon: Icons.analytics,
      accentColor: Color(0xFFD50000),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("Join Our Team"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        itemCount: jobPostings.length,
        itemBuilder:
            (context, index) => AnimatedJobCard(
              job: jobPostings[index],
              index: index,
              isDark: isDark,
            ),
      ),
    );
  }
}

class AnimatedJobCard extends StatefulWidget {
  final JobPosting job;
  final int index;
  final bool isDark;

  const AnimatedJobCard({
    required this.job,
    required this.index,
    required this.isDark,
  });

  @override
  State<AnimatedJobCard> createState() => _AnimatedJobCardState();
}

class _AnimatedJobCardState extends State<AnimatedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    );

    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animation),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      widget.isDark
                          ? widget.job.accentColor.withOpacity(0.2)
                          : widget.job.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: widget.job.accentColor.withOpacity(
                        widget.isDark ? 0.8 : 0.2,
                      ),
                      child: Icon(
                        widget.job.icon,
                        color:
                            widget.isDark
                                ? Colors.white
                                : widget.job.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.job.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.job.location,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(widget.job.type, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.send),
                        label: Text("Apply Now"),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.job.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
