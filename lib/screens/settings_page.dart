import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              snap: false,
              toolbarHeight: 60.0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                // titlePadding: EdgeInsets.only(bottom:20.0),
                title: Text("Settings",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w400,
                    )),
                // titlePadding: EdgeInsets.only(bottom:100.0),
                expandedTitleScale: 2,
                // background: const Image(
                //     fit: BoxFit.fill,
                //     image: NetworkImage(
                //       "https://th.bing.com/th/id/OIP.YRIUUjhcIMvBEf_bbOdpUwHaEU?rs=1&pid=ImgDetMain",
                //       scale: 0.4,
                //     )),
                // background: Color(0xFF000000),
              ),
            ),
          ];
        },
        body: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Theme.of(context).colorScheme.shadow,
            ),
            child: const SingleChildScrollView(
                child: Column(children: [
              Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Try Switching to Dark Theme'))
            ])),
          ),
        ),
      ),
    );
  }
}
