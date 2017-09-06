#include <gtk/gtk.h>
#include <stdlib.h>

static void onclick(GtkWidget *widget, gpointer command)
{
	system((const char*)command);
}

static void activate(GtkApplication *app, gpointer user_data)
{
	GtkWidget *window = gtk_application_window_new(app);
	gtk_window_set_title(GTK_WINDOW (window), "postmarketOS demos");

	GtkWidget *button_box = gtk_button_box_new(
		GTK_ORIENTATION_VERTICAL);
	gtk_container_add(GTK_CONTAINER (window), button_box);

	const char *programs[] = {
		"weston-presentation-shm (Animation)",
			"weston-presentation-shm &",
		"weston-simple-damage (Animation)",
			"weston-simple-damage &",
		"weston-smoke (Touch)",
			"weston-smoke &",
		"weston-editor (Touch)",
			"weston-editor &",
		"htop (Terminal)",
			"weston-terminal --shell=/usr/bin/htop &",
		"Firefox (XWayland)",
			"firefox &",
		"GTK3 Demo",
			"gtk3-demo &",
		"Restart Weston",
			"killall weston &",
		"Shutdown",
			"poweroff &"
	};

	for(int i=0;i<(sizeof(programs) / sizeof(const char*));i+=2)
	{
		const char *title = programs[i];
		const char *command = programs[i+1];

		GtkWidget *button = gtk_button_new_with_label(title);
		gtk_widget_set_size_request(button, 200, 70);
		g_signal_connect(button, "clicked", G_CALLBACK (onclick),
				(void*)command);
		gtk_container_add(GTK_CONTAINER(button_box), button);
	}
	gtk_widget_show_all (window);
}

int main (int argc, char **argv)
{
	GtkApplication *app = gtk_application_new("org.postmarketos.demos",
		G_APPLICATION_FLAGS_NONE);
	g_signal_connect (app, "activate", G_CALLBACK(activate), NULL);
	int status = g_application_run(G_APPLICATION(app), argc, argv);
	g_object_unref(app);
	return status;
}
