package com.example.flutter_nekokit;

interface ISagerNetService {
    void startVpn(String config, boolean enableKillSwitch);
    void stopVpn();
    String getVpnStatus();
    String getConnectionStats();
    String getVersion();
    void updateVpnConfig(String config);
    void enableKillSwitch();
    void disableKillSwitch();
    boolean isKillSwitchEnabled();
}

