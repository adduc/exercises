package main

import (
	"context"
	"fmt"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

type App struct {
	ctx       context.Context
	startedAt time.Time
}

func NewApp() *App {
	return &App{
		startedAt: time.Now(),
	}
}

func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
}

func (a *App) SystemInfo() string {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	uptime := time.Since(a.startedAt).Round(time.Second)

	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)
	heapMB := float64(memStats.Alloc) / 1024 / 1024

	rss := "unavailable"
	if rssBytes, err := processTreeRSSBytes(os.Getpid()); err == nil {
		rss = fmt.Sprintf("%.1f MB", float64(rssBytes)/1024/1024)
	}

	return fmt.Sprintf(
		"Go %s on %s/%s\nHostname: %s\nUptime: %s\nGo heap: %.1f MB\nTotal RSS (incl. WebKit): %s",
		runtime.Version(), runtime.GOOS, runtime.GOARCH, hostname, uptime, heapMB, rss,
	)
}

// processTreeRSSBytes sums the resident set size of pid and all of its
// descendants. WebKitGTK splits rendering and networking into separate
// sandboxed child processes, so the main process's RSS alone significantly
// understates the app's actual memory footprint.
func processTreeRSSBytes(pid int) (uint64, error) {
	total, err := processRSSBytes(pid)
	if err != nil {
		return 0, err
	}

	for _, childPID := range childPIDs(pid) {
		if childRSS, err := processTreeRSSBytes(childPID); err == nil {
			total += childRSS
		}
	}

	return total, nil
}

// childPIDs returns the direct child PIDs of pid's main thread, as reported
// by the Linux-specific /proc/<pid>/task/<pid>/children file.
func childPIDs(pid int) []int {
	data, err := os.ReadFile(fmt.Sprintf("/proc/%d/task/%d/children", pid, pid))
	if err != nil {
		return nil
	}

	var children []int
	for field := range strings.FieldsSeq(string(data)) {
		if childPID, err := strconv.Atoi(field); err == nil {
			children = append(children, childPID)
		}
	}

	return children
}

// processRSSBytes reads the resident set size of pid from /proc/<pid>/status.
func processRSSBytes(pid int) (uint64, error) {
	data, err := os.ReadFile(fmt.Sprintf("/proc/%d/status", pid))
	if err != nil {
		return 0, err
	}

	for line := range strings.SplitSeq(string(data), "\n") {
		if !strings.HasPrefix(line, "VmRSS:") {
			continue
		}

		fields := strings.Fields(line)
		if len(fields) < 2 {
			return 0, fmt.Errorf("unexpected VmRSS line: %q", line)
		}

		kb, err := strconv.ParseUint(fields[1], 10, 64)
		if err != nil {
			return 0, err
		}

		return kb * 1024, nil
	}

	return 0, fmt.Errorf("VmRSS not found in /proc/%d/status", pid)
}
