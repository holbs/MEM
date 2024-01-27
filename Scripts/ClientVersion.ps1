Try {
    [version](Get-CimInstance -NameSpace Root\CCM -Class SMS_Client -ErrorAction Stop).ClientVersion
} Catch {
    Return "Client not detected"
}
