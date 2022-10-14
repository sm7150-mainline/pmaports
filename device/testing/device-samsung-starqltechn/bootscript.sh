setenv bootargs 'console=tty1 loglevel=15 clk_ignore_unused'

bootm $prevbl_initrd_start_addr
