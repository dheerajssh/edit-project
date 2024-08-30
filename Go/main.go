package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"net"
	"os"
	"strings"
	"time"
)

func main() {
	reader := bufio.NewReader(os.Stdin)

	fmt.Print("Enter Name: ")
	name, _ := reader.ReadString('\n')
	name = strings.TrimSpace(name)

	fmt.Print("Enter Org ID: ")
	orgID, _ := reader.ReadString('\n')
	orgID = strings.TrimSpace(orgID)

	fmt.Print("Enter Subnet Start (e.g., 192.168.1.0): ")
	subnetStart, _ := reader.ReadString('\n')
	subnetStart = strings.TrimSpace(subnetStart)

	fmt.Print("Enter Subnet End (e.g., 192.168.1.255): ")
	subnetEnd, _ := reader.ReadString('\n')
	subnetEnd = strings.TrimSpace(subnetEnd)

	ip, err := assignRandomIP(subnetStart, subnetEnd)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	fmt.Printf("Assigned IP to %s (Org: %s): %s\n", name, orgID, ip)
}

func assignRandomIP(startIP, endIP string) (string, error) {
	start := net.ParseIP(startIP).To4()
	end := net.ParseIP(endIP).To4()

	if start == nil || end == nil {
		return "", fmt.Errorf("invalid IP address")
	}

	startInt := ipToInt(start)
	endInt := ipToInt(end)

	if startInt >= endInt {
		return "", fmt.Errorf("start IP must be less than end IP")
	}

	rand.Seed(time.Now().UnixNano())
	randomIPInt := rand.Intn(endInt-startInt) + startInt
	randomIP := intToIP(randomIPInt)

	return randomIP.String(), nil
}

func ipToInt(ip net.IP) int {
	return int(ip[0])<<24 + int(ip[1])<<16 + int(ip[2])<<8 + int(ip[3])
}

func intToIP(ipInt int) net.IP {
	return net.IPv4(
		byte(ipInt>>24),
		byte((ipInt>>16)&0xFF),
		byte((ipInt>>8)&0xFF),
		byte(ipInt&0xFF),
	)
}
