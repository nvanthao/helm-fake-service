package main

import (
	"context"
	"dagger/helm-fake-service/internal/dagger"
	"fmt"
	"log"
	"time"
)

type HelmFakeService struct {
	// +private
	Source *dagger.Directory
}

const (
	REPLICATED_APP = "gerard-helm-fake-service"
)

func New(
	// Project source directory
	//
	// +defaultPath="/"
	source *dagger.Directory) *HelmFakeService {
	return &HelmFakeService{
		Source: source,
	}
}

func (m *HelmFakeService) CreateReplicatedRelease(ctx context.Context, token *dagger.Secret) (string, error) {
	version := m.generateVersion(ctx)
	packagedDir := m.PrepareReplicatedRelease(ctx, version)

	return dag.Container().
		From("replicated/vendor-cli:latest").
		WithDirectory("/src", packagedDir).
		WithEnvVariable("REPLICATED_APP", REPLICATED_APP).
		WithSecretVariable("REPLICATED_API_TOKEN", token).
		WithExec([]string{"/replicated", "release", "create", "--yaml-dir", "/src", "--promote", "Unstable", "--version", version}).
		Stdout(ctx)
}

func (m *HelmFakeService) PrepareReplicatedRelease(ctx context.Context, version string) *dagger.Directory {
	releaseDir := m.Source.Directory("replicated")

	// lint chart
	_, err := m.Lint(ctx)
	if err != nil {
		log.Fatalf("Failed to lint Helm chart: %v", err)
	}

	// package Helm chart
	appHelmChart := m.Package(ctx, version)
	appHelmChartName, _ := appHelmChart.Name(ctx)

	// update KOTS HelmChart CR version
	baseContainer := m.Base()
	return baseContainer.
		WithDirectory("/src", releaseDir).
		WithWorkdir("/src").
		WithExec([]string{"apk", "add", "yq"}).
		WithExec([]string{"yq", "-i", fmt.Sprintf(".spec.chart.chartVersion=\"%s\"", version), "kots-chart.yaml"}).
		WithFile(appHelmChartName, appHelmChart).
		Directory("/src")
}

func (m *HelmFakeService) Base() *dagger.Container {
	return dag.Container().From("alpine:latest")
}

// Lint the Helm chart
func (m *HelmFakeService) Lint(ctx context.Context) (string, error) {
	chart := m.chart()
	return chart.Lint().Stdout(ctx)
}

// Package the Helm chart
func (m *HelmFakeService) Package(ctx context.Context, version string) *dagger.File {
	chart := m.chart()
	return chart.Package(dagger.HelmChartPackageOpts{
		Version:    version,
		AppVersion: version,
	}).File()
}

func (m *HelmFakeService) chart() *dagger.HelmChart {
	chart := m.Source.Directory("app")
	return dag.Helm(dagger.HelmOpts{
		Version: "3.17.1",
	}).Chart(chart)
}

// Generates a version string based on the current date, branch name, and commit hash
func (m *HelmFakeService) generateVersion(ctx context.Context) string {
	// yyyy.mm.dd.hhmmss-<branch_name>-hash
	date := time.Now().Format("2006.01.02-150405")
	branch, err := dag.GitInfo(m.Source).Branch(ctx)
	if err != nil {
		log.Fatalf("Failed to get branch: %v", err)
	}
	hash, err := dag.GitInfo(m.Source).CommitHash(ctx)
	if err != nil {
		log.Fatalf("Failed to get commit hash: %v", err)
	}
	hash = hash[:7]
	return fmt.Sprintf("%s-%s-%s", date, branch, hash)
}
