let stream1 = new MediaStream();
let stream2 = new MediaStream();

const pc1 = new RTCPeerConnection();
pc1.onnegotiationneeded = handleNegotiationNeededEvent1;

pc1.ontrack = function(event) {
  stream1.addTrack(event.track);
  videoElem1.srcObject = stream1;
}

pc1.oniceconnectionstatechange = e => log(pc1.iceConnectionState)

async function handleNegotiationNeededEvent1() {
  let offer = await pc1.createOffer();
  await pc1.setLocalDescription(offer);
  getRemoteSdp(pc1, 'demo1');
}

const pc2 = new RTCPeerConnection();
pc2.onnegotiationneeded = handleNegotiationNeededEvent2;
pc2.ontrack = function(event) {
  stream2.addTrack(event.track);
  videoElem2.srcObject = stream2;
}

pc2.oniceconnectionstatechange = e => log(pc2.iceConnectionState)

async function handleNegotiationNeededEvent2() {
  let offer = await pc2.createOffer();
  await pc2.setLocalDescription(offer);
  getRemoteSdp(pc2, 'demo2');
}



$(document).ready(function() {
  getCodecInfo(pc1, 'demo1');
  getCodecInfo(pc2, 'demo2');
});

function getCodecInfo(pc, suuid) {
  $.get("../stream/codec/" + suuid, function(data) {
    try {
      data = JSON.parse(data);
    } catch (e) {
      console.log(e);
    } finally {
      $.each(data,function(index,value){
        pc.addTransceiver(value.Type, {
          'direction': 'sendrecv'
        })
      })
    }
  });
}

let sendChannel = null;

function getRemoteSdp(pc, suuid) {
  $.post("../stream/receiver/"+ suuid, {
    suuid: suuid,
    data: btoa(pc.localDescription.sdp)
  }, function(data) {
    try {
      pc.setRemoteDescription(new RTCSessionDescription({
        type: 'answer',
        sdp: atob(data)
      }))
    } catch (e) {
      console.warn(e);
    }
  });
}
