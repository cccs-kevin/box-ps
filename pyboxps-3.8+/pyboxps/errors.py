####################################################################################################
class BoxPSError(Exception):
    pass


####################################################################################################
class BoxPSEnvError(BoxPSError):
    pass


####################################################################################################
class BoxPSNoEnvVarError(BoxPSEnvError):
    pass


####################################################################################################
class BoxPSBadEnvVarError(BoxPSEnvError):
    pass


####################################################################################################
class BoxPSBadInstallError(BoxPSEnvError):
    pass


####################################################################################################
class BoxPSMemError(BoxPSEnvError):
    pass


####################################################################################################
class BoxPSDependencyError(BoxPSEnvError):
    pass


####################################################################################################
class BoxPSSandboxError(BoxPSError):
    pass


####################################################################################################
class BoxPSTimeoutError(BoxPSSandboxError):
    pass


####################################################################################################
class BoxPSScriptSyntaxError(BoxPSSandboxError):
    pass


####################################################################################################
class BoxPSReportError(BoxPSError):
    pass
