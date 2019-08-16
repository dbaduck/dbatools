function New-DbaServerRole {
    <#
    .SYNOPSIS
        Create new server-level roles.

    .DESCRIPTION
        The New-DbaServerRole create new roles on instance(s) of SQL Server.

   .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER ServerRole
        Server-Level role to be created.

    .PARAMETER Owner
        The owner of the role. If not specified will assume the default dbo.

    .PARAMETER InputObject
        Enables piped input from Get-DbaDatabase

    .PARAMETER WhatIf
        Shows what would happen if the command were to run. No actions are actually performed.

    .PARAMETER Confirm
        Prompts you for confirmation before executing any changing operations within the command.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Role, Database, Security
        Author: Cláudio Silva (@ClaudioESSilva), https://claudioessilva.eu
        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/New-DbaServerRole

    .EXAMPLE
        PS C:\> New-DbaServerRole -SqlInstance sql2017a -Database db1 -Role 'dbExecuter'

        Will create a new role named dbExecuter within db1 on sql2017a instance.

    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [String[]]$ServerRole,
        [String]$Owner,
        [switch]$EnableException
    )
    process {
        if (-not $ServerRole) {
            Stop-Function -Message "You must specify a new server-role name. Use -ServerRole parameter."
            return
        }

        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $SqlCredential
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            $serverroles = $server.Roles

            foreach ($role in $ServerRole) {
                if ($serverroles | Where-Object Name -eq $role) {
                    Stop-Function -Message "The $role role already exist within database $db on instance $server." -Target $db -Continue
                }

                Write-Message -Level Verbose -Message "Add roles to Instance $server"

                if ($Pscmdlet.ShouldProcess("Creating new Serve-role $role on $server")) {
                    try {
                        $newServerRole = New-Object -TypeName Microsoft.SqlServer.Management.Smo.ServerRole
                        $newServerRole.Name = $role
                        $newServerRole.Parent = $server

                        if ($Owner) {
                            $newServerRole.Owner = $Owner
                        }

                        $newServerRole.Create()

                        Add-Member -Force -InputObject $newServerRole -MemberType NoteProperty -Name ComputerName -value $server.ComputerName
                        Add-Member -Force -InputObject $newServerRole -MemberType NoteProperty -Name InstanceName -value $server.ServiceName
                        Add-Member -Force -InputObject $newServerRole -MemberType NoteProperty -Name SqlInstance -value $server.DomainInstanceName

                        Select-DefaultView -InputObject $newServerRole -Property ComputerName, InstanceName, SqlInstance, Name, Owner
                    } catch {
                        Stop-Function -Message "Failure" -ErrorRecord $_ -Continue
                    }
                }
            }
        }
    }
}