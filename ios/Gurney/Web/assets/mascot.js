// Shared Three.js models. Gameplay, title artwork, and icons use these exact meshes.
(function (scope) {
  function createPatient(THREE, color = 0xf0c7a5) {
    const root = new THREE.Group();
    const skin = new THREE.MeshStandardMaterial({color, roughness: .92});
    const gown = new THREE.MeshStandardMaterial({color: 0x91c8d3, roughness: .95});
    const white = new THREE.MeshStandardMaterial({color: 0xfffaf0, roughness: .9});
    const ink = new THREE.MeshStandardMaterial({color: 0x253547, roughness: .95});
    function oval(x,y,z,sx,sy,sz,material) {
      const mesh = new THREE.Mesh(new THREE.SphereGeometry(1,16,12),material);
      mesh.position.set(x,y,z);mesh.scale.set(sx,sy,sz);mesh.castShadow=true;root.add(mesh);return mesh;
    }
    // A continuous soft silhouette: no separate human neck or age-specific anatomy.
    oval(0,1.25,0,.5,.55,.38,skin);
    const cloth = new THREE.Mesh(new THREE.CylinderGeometry(.49,.55,.69,24,1),gown);
    cloth.position.y=.66;cloth.scale.z=.82;cloth.castShadow=true;root.add(cloth);
    oval(0,.34,0,.55,.105,.451,gown);
    for(const side of [-1,1]) {
      const shoulder=oval(side*.48,.94,0,.19,.14,.19,gown);
      const sleeveRoot=new THREE.Group();sleeveRoot.position.set(side*.535,.825,0);sleeveRoot.rotation.z=side*.3;root.add(sleeveRoot);
      const sleeveMaterial=gown.clone();sleeveMaterial.side=THREE.DoubleSide;
      const sleeve=new THREE.Mesh(new THREE.CylinderGeometry(.19,.158,.29,20,1,true),sleeveMaterial);sleeve.castShadow=true;sleeveRoot.add(sleeve);
      const cuff=new THREE.Mesh(new THREE.TorusGeometry(.158,.012,5,20),gown);
      cuff.position.y=-.145;cuff.rotation.x=Math.PI/2;sleeveRoot.add(cuff);
      const arm=oval(side*.6,.64,.015,.13,.24,.13,skin);arm.rotation.z=side*.22;
      const leg=new THREE.Mesh(new THREE.CylinderGeometry(.12,.12,.37,16),skin);
      leg.position.set(side*.22,.30,.015);leg.castShadow=true;leg.userData.isLeg=true;root.add(leg);
      oval(side*.22,.115,.065,.125,.105,.17,skin).userData.isLeg=true;
      oval(side*.19,1.47,.342,.072,.009,.014,ink);
    }
    // User sketch: sleepy slit eyes and a simple round nose; no cartoon grin.
    // Hemisphere seated flush against the front of the face.
    const nose=new THREE.Mesh(new THREE.SphereGeometry(.135,24,16,0,Math.PI*2,0,Math.PI/2),skin);
    nose.rotation.x=Math.PI/2;nose.position.set(0,1.32,.36);nose.castShadow=true;root.add(nose);
    const hair=new THREE.MeshStandardMaterial({color:0x554337,roughness:1});
    for(const [x,lean,height] of [[-.24,-.06,.09],[-.065,-.025,.12],[.13,.045,.10],[.285,.05,.075]]){
      const y=1.25+.55*Math.sqrt(1-(x/.5)**2);
      const strand=new THREE.CatmullRomCurve3([
        new THREE.Vector3(x,y,-.02),new THREE.Vector3(x+lean*.25,y+height*.7,-.02),new THREE.Vector3(x+lean,y+height,-.025)
      ]);
      const mesh=new THREE.Mesh(new THREE.TubeGeometry(strand,6,.008,4,false),hair);mesh.castShadow=true;root.add(mesh);
    }
    const band=new THREE.Mesh(new THREE.TorusGeometry(.127,.024,5,12),white);
    band.position.set(-.625,.54,.015);band.rotation.x=Math.PI/2;band.rotation.y=-.22;root.add(band);
    for(const x of [-.19,0,.19])for(const y of [.54,.76]){
      const dash=new THREE.Mesh(new THREE.BoxGeometry(.062,.012,.014),ink);
      const radius=.55-(y-.315)/.69*.06;dash.position.set(x,y,Math.sqrt(radius*radius-x*x)*.82+.008);dash.rotation.y=Math.asin(x/radius);root.add(dash);
    }
    for(const part of root.children)if(!part.userData.isLeg)part.position.y+=.12;
    root.userData.skin=skin;
    return root;
  }
  function createBed(THREE) {
    const root=new THREE.Group();
    const frame=new THREE.MeshStandardMaterial({color:0xcdd6e0,metalness:.6,roughness:.35});
    const pad=new THREE.MeshStandardMaterial({color:0xdfe6ee,roughness:.85});
    const wheelMat=new THREE.MeshStandardMaterial({color:0x111418,roughness:.9});
    function block(w,h,d,material,x,y,z){const m=new THREE.Mesh(new THREE.BoxGeometry(w,h,d),material);m.position.set(x,y,z);m.castShadow=true;root.add(m);return m;}
    block(1.4,.25,3.2,pad,0,1.05,0);block(1.5,.12,3.4,frame,0,.9,0);
    const wheels=[];
    for(const x of [-.6,.6])for(const z of [-1.4,1.4]){
      const leg=new THREE.Mesh(new THREE.CylinderGeometry(.06,.06,.8,16),frame);leg.position.set(x,.45,z);leg.castShadow=true;root.add(leg);
      const wheel=new THREE.Mesh(new THREE.CylinderGeometry(.18,.18,.12,16),wheelMat);wheel.rotation.z=Math.PI/2;wheel.position.set(x,.18,z);wheel.castShadow=true;root.add(wheel);wheels.push(wheel);
    }
    block(1.5,.5,.1,frame,0,1.4,-1.6);
    root.userData.stockWheels=wheels;
    return root;
  }
  function createRider(THREE, standing=false, color) {
    const root=new THREE.Group(),patient=createPatient(THREE,color);
    patient.scale.setScalar(1.1);
    if(standing)patient.position.y=1.18;
    else{patient.rotation.x=-Math.PI/2;patient.position.set(0,1.68,.95);}
    root.add(patient);root.userData.patient=patient;return root;
  }
  function addLighting(THREE,scene){
    const hemi=new THREE.HemisphereLight(0xbfd4ff,0x202830,.7);
    const sun=new THREE.DirectionalLight(0xffffff,2.2);sun.position.set(40,70,30);sun.castShadow=true;
    const fill=new THREE.AmbientLight(0xffffff,.45);
    scene.add(hemi,sun,fill);return {hemi,sun,fill};
  }
  scope.GurneyArt={createPatient,createBed,createRider,addLighting};
})(globalThis);
