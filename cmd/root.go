package cmd

import (
	"fmt"
	"os"

	"github.com/samzong/cli-template/internal/config"
	"github.com/spf13/cobra"
)

var (
	NAME      = "mycli"
	Version   = "dev"
	BuildTime = "unknown"
	cfgFile   string
	verbose   bool
	cfg       *config.Config

	rootCmd = &cobra.Command{
		Use:     NAME,
		Short:   NAME + " is a CLI tool",
		Long:    NAME + " is a powerful CLI tool that helps you manage resources.",
		Version: fmt.Sprintf("%s (built at %s)", Version, BuildTime),
		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			if cmd.Name() == "version" || cmd.Name() == "help" || cmd.Name() == "completion" {
				return nil
			}

			var err error
			cfg, err = config.LoadConfig(cfgFile, NAME)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Warning: Failed to load config: %s\n", err)
				cfg = &config.DefaultConfig
			}

			if verbose {
				fmt.Printf("Using config file: %s\n", config.GetConfigPath())
			}

			return nil
		},
	}
)

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	rootCmd.PersistentFlags().StringVar(
		&cfgFile,
		"config",
		"",
		fmt.Sprintf("config file (default is $HOME/.%s.yaml)", NAME))
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "enable verbose output")
	rootCmd.AddCommand(versionCmd)
}
