// CI/CD pipeline: GitHub -> Jenkins -> Azure VM (nginx)
// Works whether Jenkins runs on Windows or Linux.
pipeline {
    agent any

    environment {
        VM_IP    = '20.197.61.227'   // from: terraform output public_ip
        VM_USER  = 'azureuser'
        WEB_ROOT = '/var/www/html'
        SSH_OPTS = '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
    }

    // Check GitHub for new commits every 2 minutes (Poll SCM)
    triggers {
        pollSCM('H/2 * * * *')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    if (!fileExists('app/index.html')) {
                        error 'Build failed: app/index.html not found'
                    }
                    if (isUnix()) {
                        sh 'rm -f site.tar.gz && tar -czf site.tar.gz -C app .'
                    } else {
                        bat 'if exist site.tar.gz del site.tar.gz'
                        bat 'tar -czf site.tar.gz -C app .'
                    }
                }
                archiveArtifacts artifacts: 'site.tar.gz', fingerprint: true
            }
        }

        stage('Deploy to Azure VM') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'azure-vm-ssh',
                                                   keyFileVariable: 'SSH_KEY')]) {
                    script {
                        if (isUnix()) {
                            sh '''
                                scp $SSH_OPTS -i "$SSH_KEY" site.tar.gz $VM_USER@$VM_IP:/tmp/site.tar.gz
                                ssh $SSH_OPTS -i "$SSH_KEY" $VM_USER@$VM_IP "rm -rf $WEB_ROOT/* && tar -xzf /tmp/site.tar.gz -C $WEB_ROOT && rm /tmp/site.tar.gz"
                            '''
                        } else {
                            // Windows OpenSSH refuses keys readable by other users, so lock the temp key down first
                            bat '''
                                icacls "%SSH_KEY%" /inheritance:r
                                for /f "delims=" %%u in ('whoami') do icacls "%SSH_KEY%" /grant:r "%%u":R
                                scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -i "%SSH_KEY%" site.tar.gz %VM_USER%@%VM_IP%:/tmp/site.tar.gz
                                ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=NUL -i "%SSH_KEY%" %VM_USER%@%VM_IP% "rm -rf %WEB_ROOT%/* && tar -xzf /tmp/site.tar.gz -C %WEB_ROOT% && rm /tmp/site.tar.gz"
                            '''
                        }
                    }
                }
            }
        }

        stage('Verify') {
            steps {
                script {
                    if (isUnix()) {
                        sh 'curl -sf http://$VM_IP/ > /dev/null'
                    } else {
                        bat 'curl -sf http://%VM_IP%/ > NUL'
                    }
                }
                echo "Live at http://${env.VM_IP}"
            }
        }
    }

    post {
        success { echo 'Deployment succeeded.' }
        failure { echo 'Deployment failed - check the stage logs above.' }
    }
}
