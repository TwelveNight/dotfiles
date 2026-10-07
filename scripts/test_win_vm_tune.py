"""Validate tuning transformations without modifying a libvirt domain."""
import importlib.machinery
import importlib.util
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

SOURCE = Path(__file__).resolve().parents[1] / "dot_local/scripts/executable_win-vm-tune"
sys.dont_write_bytecode = True
loader = importlib.machinery.SourceFileLoader("win_vm_tune", str(SOURCE))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)
XML = '''<domain type="kvm"><name>test</name>
<memory unit="KiB">5242880</memory><currentMemory unit="KiB">5242880</currentMemory>
<vcpu>6</vcpu><cpu mode="host-passthrough"/><features><hyperv mode="custom">
<relaxed state="on"/><vapic state="on"/><spinlocks state="on" retries="8191"/>
</hyperv></features><devices><interface><model type="e1000e"/></interface>
<disk><driver type="qcow2"/><source file="test.qcow2"/></disk></devices></domain>'''
CAPS = '''<domainCapabilities><features><hyperv supported="yes"><enum name="features">
<value>vpindex</value><value>synic</value><value>stimer</value><value>tlbflush</value><value>ipi</value>
</enum><defaults><stimer_direct>on</stimer_direct></defaults></hyperv></features></domainCapabilities>'''


class TuningTests(unittest.TestCase):
    def test_preserves_devices_cpu_and_existing_features(self):
        result, old, added = module.tune(XML, CAPS, 8)
        root = ET.fromstring(result)
        before = ET.fromstring(XML)
        ET.indent(before, space="  ")
        self.assertEqual(old, 5242880)
        self.assertEqual(root.findtext("memory"), "8388608")
        self.assertEqual(root.findtext("currentMemory"), "8388608")
        for name in ("devices", "cpu", "vcpu"):
            self.assertEqual(ET.tostring(root.find(name)).split(), ET.tostring(before.find(name)).split())
        self.assertEqual(set(added), set(module.FEATURES))
        self.assertEqual(root.find("features/hyperv/spinlocks").get("retries"), "8191")
        self.assertEqual(root.find("features/hyperv/stimer/direct").get("state"), "on")

    def test_idempotent(self):
        first, _, _ = module.tune(XML, CAPS, 8)
        second, _, added = module.tune(first, CAPS, 8)
        self.assertEqual(first, second)
        self.assertFalse(added)

    def test_rejects_memory_reduction(self):
        with self.assertRaises(ValueError):
            module.tune(XML, CAPS, 4)

    def test_does_not_enable_unsupported_features(self):
        result, _, added = module.tune(XML, CAPS.replace("<value>ipi</value>", ""), 8)
        self.assertNotIn("ipi", added)
        self.assertIsNone(ET.fromstring(result).find("features/hyperv/ipi"))

    def test_preserves_explicit_disabling(self):
        xml = XML.replace('<relaxed state="on"/>', '<relaxed state="on"/><ipi state="off"/>')
        with self.assertRaises(ValueError):
            module.tune(xml, CAPS, 8)

    def test_rejects_hotplug(self):
        with self.assertRaises(ValueError):
            module.tune(XML.replace("<vcpu>", '<maxMemory unit="GiB">16</maxMemory><vcpu>'), CAPS, 8)


if __name__ == "__main__":
    unittest.main()
