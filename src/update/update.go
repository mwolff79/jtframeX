package update

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"math/rand"
	"os"
	"path/filepath"
	"strings"
	"text/template"
	"time"
)

type Customs map[string]string
type Groups map[string]string

type Config struct {
	Max_jobs            int
	Git, Nohdmi   		  bool
	Nosnd, Actions, Seed  bool
	Private,  Nodbg  		bool
	Skip, SkipROM				bool
	Group, extra 		  	string
	Beta, Stamp, Defs   string
	cores               []string
	CoreList            string
	Targets             map[string]bool
	// enabled platforms
	groups  Groups
	customs Customs
}

func make_key(target, core string) string {
	return core + "." + target
}

func parse_cfgfile(cfg *Config, file *os.File) {
	scanner := bufio.NewScanner(file)
	scanner.Split(bufio.ScanLines)
	linecnt := 0

	var cur_group string
	var cur_custom []string

	const (
		Group_parsing = iota
		Custom_parsing
		Dangling_parsing
	)

	var cur_parsing int
	cur_parsing = Dangling_parsing

	for scanner.Scan() {
		linecnt++
		line := strings.TrimSpace(scanner.Text())
		if len(line) == 0 || line[0] == '#' {
			continue
		}
		if line[0] == '[' {
			idx := strings.Index(line, "]")
			if idx == -1 {
				fmt.Println("jtupdate: Malformed expression at .jtupdate line ", linecnt)
				log.Fatal("Bad .jtupdate file")
			}
			parts := strings.SplitN(strings.TrimSpace(line[1:idx]), ":", 2)
			if len(parts) == 1 { // Group specification
				_, ok := cfg.groups[parts[0]]
				if ok {
					log.Fatal(fmt.Sprintf("jtupdate: error in .jtupdate line %d the group %s had already been defined", linecnt, parts))
				}
				cfg.groups[parts[0]] = ""
				cur_group = parts[0]
				cur_parsing = Group_parsing
			} else {
				// keyword
				switch parts[0] {
				case "custom":
					{
						cur_custom = strings.Split(parts[1], "|")
						cur_parsing = Custom_parsing
					}
				default:
					{
						log.Fatal(fmt.Sprintf("jtupdate: error in .jtupdate line %d. Unrecognized keyword %s", linecnt, parts[0]))
					}
				}
			}
			continue
		}
		switch cur_parsing {
		case Group_parsing:
			{
				var g string
				g = cfg.groups[cur_group]
				if len(g) == 0 {
					g = line
				} else {
					g = g + "," + line
				}
				cfg.groups[cur_group] = g
			}
		case Custom_parsing:
			{
				s := strings.SplitN(line, " ", 2)
				if len(s) < 2 {
					log.Fatal(fmt.Sprintf("jtupdate: error in .jtupdate line %d. Custom command is empty", linecnt))
				}
				for _, t := range cur_custom {
					cfg.customs[make_key(t, s[0])] = s[1]
				}
			}
		default:
			log.Fatal(fmt.Sprintf("jtupdate: error in .jtupdate line %d. Dangling text", linecnt))
		}
	}
}

func update_actions(jtroot string, cfg Config) {
	folder := filepath.Join(jtroot, ".github", "workflows")
	if err := os.MkdirAll( folder, 0775 ); err!=nil {
		fmt.Println("jtframe update: problem creating ", folder, "\n\t", err )
		os.Exit(1)
	}
	t := template.Must(template.New("yaml").Parse(yaml_code))
	rand.Seed(time.Now().UnixNano())

	for target, _ := range cfg.Targets {
		if target == "mister" || target == "sockit" || target == "de1soc" || target == "de10standard" {
			continue // not ready yet
		}
		for _, core := range cfg.cores {
			key := make_key(target, core)
			data := struct {
				Corename, Target, Extra, Seed, Branches, Docker, OtherBranch string
			}{
				Corename:    core,
				Target:      target,
				Docker:      "jtcore13",
				Extra:       cfg.customs[key],
				Seed:        "",
				OtherBranch: "",
			}
			if target == "mister" {
				data.Docker = "jtcore:20"
			}
			// MiST gets compiled for each update on the master branch
			if target == "mist" {
				data.OtherBranch = "master"
			}
			for cnt := 0; cnt < 5; cnt++ {
				var buffer bytes.Buffer
				if cfg.Seed {
					data.Seed = fmt.Sprintf("--seed %d", rand.Int31())
				}
				err := t.Execute(&buffer, data)
				if err != nil {
					log.Fatal(err)
				}
				aux := bytes.ReplaceAll(buffer.Bytes(), []byte("¿¿"), []byte("{{"))
				aux = bytes.ReplaceAll(aux, []byte("??"), []byte("}}"))
				//fmt.Println(string(aux))
				// Save to file
				var f *os.File
				fname := folder + target + "_" + core
				if cfg.Seed {
					fname += fmt.Sprintf("_%d", cnt)
				}
				fname = fname + ".yml"
				f, err = os.Create(fname)
				if err != nil {
					log.Fatal(err)
				}
				//fmt.Println(fname)
				f.Write(aux)
				f.Close()
				if !cfg.Seed {
					break
				}
			}
		}
	}
	fmt.Println("Remember to add the secrets to the GitHub repository")
}

func dump_output(cfg Config) {
	var all_cores []string
	if len(cfg.Group) != 0 {
		s, e := cfg.groups[cfg.Group]
		if !e {
			log.Fatal("Specified group cannot be found in .jtupdate file")
		}
		all_cores = strings.Split(s, ",")
	} else {
		all_cores = cfg.cores
	}
	// Update MRA/JSON and sch if needed
	mra_str := "jtframe mra %s"
	sch_str := "jtframe sch %s"
	if cfg.Git {
		mra_str += " --git"
		sch_str += " --git"
	}
	if cfg.Beta != "" {
		mra_str += " --beta"
	}
	if cfg.SkipROM {
		mra_str += " --skipROM"
	}
	mra_str += "\n"
	sch_str += "\n"
	for _, each := range all_cores {
		fmt.Printf(mra_str, each)
		fmt.Printf(sch_str, each)
	}
	// Update the RBF files
	if cfg.Skip {
		return
	}
	// Prepare the build macros
	defs := make([]string,0,16)
	appendif := func(cond bool, macro ...string) {
		if cond {
			defs = append(defs, macro...)
		}

	}
	appendif(cfg.Defs!="", strings.Split(cfg.Defs, ",")...)
	appendif(cfg.Private, "JTFRAME_OSDCOLOR=(6'h20)")
	appendif(cfg.Nohdmi, "MISTER_DEBUG_NOHDMI")
	appendif(cfg.Nosnd, "NOSOUND")
	appendif(cfg.Beta != "", "BETA", "JTFRAME_CHEAT_SCRAMBLE", "JTFRAME_UNLOCKKEY="+cfg.Beta)
	for target, valid := range cfg.Targets {
		if !valid {
			continue
		}
		for _, c := range all_cores {
			key := make_key(target, c)
			cmd := "jtcore"
			if cfg.Seed {
				cmd = "jtseed 6"
			}
			jtcore := fmt.Sprintf("%s %s -%s %s %s", cmd, c, target, cfg.customs[key], cfg.extra)
			if cfg.Stamp != "" {
				jtcore += "--corestamp " + cfg.Stamp
			}
			// --git skipped if asked so, but also for all targets but mister in betas
			dogit := cfg.Git && !(cfg.Beta != "" && target != "mister")
			if dogit {
				jtcore += " --git"
			}
			if dogit || cfg.Nodbg || cfg.Beta != "" || cfg.Private {
				jtcore += " -d JTFRAME_RELEASE"
			}
			for _, each := range defs {
				each = strings.TrimSpace(each)
				if each != "" {
					jtcore += " -d " + each
				}
			}
			copy := false
			for _, each := range os.Args {
				if each == "--" {
					copy = true
					continue
				}
				if copy {
					jtcore += " " + each
				}
			}
			fmt.Println(jtcore)
		}
	}
}

func folder_exists(path string) bool {
	f, e := os.Open(path)
	f.Close()
	return e == nil
}

func require_folder(path string) {
	if !folder_exists(path) {
		log.Fatal("jtframe update: ERROR. Cannot access path ", path)
	}
}

func parse_args(cfg *Config, cores_folder string, all_args []string) {

	flag.Parse()

	for k, arg := range all_args {
		if arg == "--" {
			for j := k + 1; j < len(all_args); j++ {
				cfg.extra += all_args[j] + " "
			}
			break
		}
	}
	for _, each := range strings.Split(cfg.CoreList, ",") {
		if each == "" {
			continue
		}
		// try to append name as core
		require_folder(filepath.Join(cores_folder, each, "cfg"))
		cfg.cores = append(cfg.cores, each)
	}
	if cfg.cores == nil {
		// Get all folders in $JTROOT/cores
		f, err := os.Open(cores_folder)
		if err != nil {
			log.Fatal("jtframe update:", err)
		}
		folders, err := f.ReadDir(-1)
		if err != nil {
			log.Fatal("jtframe update:", err)
		}
		for _, each := range folders {
			if folder_exists(filepath.Join(cores_folder, each.Name(), "cfg")) {
				cfg.cores = append(cfg.cores, each.Name())
			}
		}
		f.Close()
	}
	if cfg.cores == nil {
		log.Fatal("jtframe update: no cores Specified")
	}
}

func Run(cfg *Config, all_args []string) {
	cfg.customs = make(Customs)
	cfg.groups = make(Groups)

	cores_folder := os.Getenv("CORES")
	jtroot := os.Getenv("JTROOT")

	// Sanity checks
	if len(jtroot) == 0 {
		log.Fatal("jtupdate: JTROOT was not defined")
	} else {
		require_folder(jtroot)
	}

	require_folder(cores_folder)
	if len(cores_folder) == 0 {
		log.Fatal("jtupdate: JTROOT was undefined")
	}

	parse_args(cfg, cores_folder, all_args)

	// parse .jtupdate file
	file, err := os.Open(jtroot + "/.jtupdate")
	if err == nil {
		defer file.Close()
		parse_cfgfile(cfg, file)
	}
	if cfg.cores == nil {
		// get the core list directly from the cores folder
		files, _ := ioutil.ReadDir(cores_folder)
		for _, file := range files {
			if file.IsDir() {
				path := cores_folder + "/" + file.Name()
				if folder_exists(path + "/hdl") {
					corename := path
					i := strings.LastIndex(path, "/")
					if i != -1 {
						corename = path[i+1:]
					}
					cfg.cores = append(cfg.cores, corename)
				}
			}
		}
	}
	if cfg.cores == nil {
		log.Fatal("jtupdate: you must specify at least one core to update")
	}
	if cfg.Actions {
		update_actions(jtroot, *cfg)
	} else {
		dump_output(*cfg)
	}
}

// Keep space indentation for YAML code
var yaml_code string = `
name: {{.Corename}} for {{.Target}}

on:
  push:
  	{{- if ne .Target "mist" }}
    branches:
      - build
      - {{.Target}}
      - build_{{.Corename}}{{ if .OtherBranch }}
      - {{.OtherBranch}}{{ end }}
  	{{- end}}

  workflow_dispatch:

  repository_dispatch:
    types: rebuild

jobs:

  {{.Target}}_compilation:

    env:
      FTPUSER: $¿¿ secrets.FTPUSER ??
      FTPPASS: $¿¿ secrets.FTPPASS ??

    runs-on: ubuntu-latest

    container:
      image: jotego/{{.Docker}}
      credentials:
        username: jotego
        password: $¿¿ secrets.DOCKER_LOGIN ??

    steps:
      - name: Cancel Previous Runs
        uses: styfle/cancel-workflow-action@0.9.0
        with:
          access_token: $¿¿ github.token ??
      - name: compile for {{.Target}}
        run: /docked_build.sh {{.Corename}} -{{.Target}} {{.Extra}} {{.Seed}}
`
