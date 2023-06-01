-- PipeWire's S24LE default audio format is broken in the kernel driver
table.insert(alsa_monitor.rules,
  {
    matches = {
      {
        { "node.name", "matches", "alsa_output.*.HiFi*__sink" },
      },
      {
        { "node.name", "matches", "alsa_input.*.HiFi*__source" },
      },
    },
    apply_properties = {
      ["audio.format"]           = "S16LE",
    },
  }
)

-- Disable suspend for Voice Call devices
table.insert(alsa_monitor.rules,
  {
	matches = {
	  {
	    { "node.name", "matches", "alsa_output.*.Voice_Call*__sink" },
	  },
	  {
		{ "node.name", "matches", "alsa_input.*.Voice_Call*__source" },
	  },
	},
	apply_properties = {
	  ["audio.format"] = "S16LE",
      ["session.suspend-timeout-seconds"] = 0,
	},
  }
)
