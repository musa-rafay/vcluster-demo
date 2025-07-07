pipeline {
  agent any
  parameters {
    booleanParam(name:'RUN_AGAIN', defaultValue:false,
                 description:'Re-run tests without a new approval')
  }
  environment {
    BED = 'vc-demo'              // name of the vcluster context in kubeconfig
  }

  stages {
    stage('Checkout'){ steps { checkout scm } }

    stage('Skip if last run green') {
      when { expression { !params.RUN_AGAIN } }
      steps {
        script {
          def p = currentBuild.rawBuild.getPreviousBuild()
          if (p && p.result=='SUCCESS') {
            currentBuild.result='SUCCESS'
            echo 'Previous build green → skipping.'
          }
        }
      }
    }

    stage('Detect changes') {
      steps {
        script {
          sh 'git fetch origin main --quiet'
          def diff = sh(returnStdout:true,
            script:'git diff --name-only origin/main...HEAD | cut -d/ -f1 | sort -u').trim()
          def map = ['service-alpha':'alpha','service-bravo':'bravo']
          def list = diff.split('\n').collect{ map[it] }.findAll{ it }
          env.SVCS = list ? list.join(',') : 'alpha,bravo'
          echo "Services to patch/test: ${env.SVCS}"
        }
      }
    }

    stage('Generate stable builds') {
  steps {
    //  ensure pip exists (one-off);  install PyYAML if it is missing
    sh '''
      if ! command -v pip3 >/dev/null ; then
        apt-get update -qq && apt-get install -y --no-install-recommends python3-pip
      fi
      python3 - <<'PY'
import importlib, subprocess, sys, os
try:
    importlib.import_module("yaml")
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--quiet", "PyYAML"])
PY
      python3 ci/gen_stable_builds.py
    '''
    archiveArtifacts artifacts: 'stable-builds.yml', fingerprint: true
  }
}

    stage('Deploy changed') {
      steps { sh "ci/deploy_changed.sh ${env.BED} ${env.SVCS}" }
    }

    stage('Run tests') {
      steps { sh "ci/run_tests.sh ${env.SVCS}" }
    }
  }

  post {
    success { echo '✅ All tests passed.' }
    failure { echo '❌ Tests failed.' }
  }
}
