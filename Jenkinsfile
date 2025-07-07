pipeline {
  agent any
  parameters {
    booleanParam(name:'RUN_AGAIN', defaultValue:false,
                 description:'Re-run tests without a new approval')
  }

    environment {
      KCFG_ID = 'vc-demo-kubeconfig'              
      BED_CTX = 'kubernetes-admin@kubernetes'     
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
        sh '''
          python3 -m pip install --user --quiet --break-system-packages PyYAML
          python3 ci/gen_stable_builds.py
        '''
        archiveArtifacts artifacts: 'stable-builds.yml', fingerprint: true
      }
    }

stage('Deploy changed') {
    steps {
        withCredentials([file(credentialsId: env.KCFG_ID,
                             variable: 'VC_KUBECONFIG')]) {
            sh '''
              export KUBECONFIG="$VC_KUBECONFIG"
              ci/deploy_changed.sh "$BED_CTX" "$SVCS"
            '''
        }
    }
}

stage('Run tests') {
    steps {
        withCredentials([file(credentialsId: env.KCFG_ID,
                             variable: 'VC_KUBECONFIG')]) {
            sh '''
              export KUBECONFIG="$VC_KUBECONFIG"
              ci/run_tests.sh "$SVCS"
            '''
        }
    }
}
  }

  post {
    success { echo '✅ All tests passed.' }
    failure { echo '❌ Tests failed.' }
  }
}
